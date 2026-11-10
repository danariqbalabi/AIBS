import httpx

from app.core.errors import ApiError


class SupabaseStorage:
    def __init__(self, settings):
        self.base = str(settings.supabase_url).rstrip("/") + "/storage/v1"
        self.bucket = settings.storage_bucket
        self.secret = settings.supabase_service_role_key

    def request(self, method, path, **kwargs):
        if not self.secret or not self.secret.get_secret_value():
            raise ApiError(503, "storage_not_configured", "Penyimpanan foto belum tersedia.")
        headers = {
            "apikey": self.secret.get_secret_value(),
            "Authorization": "Bearer " + self.secret.get_secret_value(),
            **kwargs.pop("headers", {}),
        }
        try:
            with httpx.Client(timeout=20) as client:
                response = client.request(method, self.base + path, headers=headers, **kwargs)
            response.raise_for_status()
            return response
        except httpx.HTTPError as exc:
            raise ApiError(
                503, "storage_unavailable", "Foto belum dapat diproses.", retryable=True
            ) from exc

    def ensure_private(self):
        try:
            metadata = self.request("GET", f"/bucket/{self.bucket}").json()
            if metadata.get("public") is not False:
                raise ApiError(
                    503, "private_bucket_required", "Konfigurasi foto privat belum siap."
                )
        except (ValueError, TypeError, AttributeError) as exc:
            raise ApiError(503, "storage_unavailable", "Penyimpanan foto belum siap.") from exc

    def upload(self, path, data):
        self.ensure_private()
        self.request(
            "POST",
            f"/object/{self.bucket}/{path}",
            content=data,
            headers={"Content-Type": "image/jpeg", "x-upsert": "false"},
        )

    def download(self, path):
        self.ensure_private()
        response = self.request("GET", f"/object/{self.bucket}/{path}")
        if len(response.content) > 6 * 1024 * 1024:
            raise ApiError(422, "image_too_large", "Foto terlalu besar.")
        return response.content

    def sign(self, path):
        self.ensure_private()
        try:
            result = self.request(
                "POST", f"/object/sign/{self.bucket}/{path}", json={"expiresIn": 60}
            ).json()
            signed = result["signedURL"]
            if not signed.startswith("/object/sign/"):
                raise ValueError("Unexpected signed URL")
            return self.base + signed
        except (ValueError, KeyError, TypeError) as exc:
            raise ApiError(503, "storage_unavailable", "Foto belum dapat dibuka.") from exc

    def delete(self, path):
        self.request("DELETE", f"/object/{self.bucket}", json={"prefixes": [path]})
