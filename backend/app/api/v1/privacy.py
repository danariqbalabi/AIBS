from fastapi import APIRouter, Depends, Query, Request, Response
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from starlette.background import BackgroundTask

from app.core.auth import User, get_user
from app.core.database import get_db
from app.core.errors import ApiError
from app.services import privacy

router = APIRouter(prefix="/api/v1/me/data", tags=["privacy"])


@router.get("/export")
def export(request: Request, user: User = Depends(get_user), db: Session = Depends(get_db)):
    archive = privacy.export_data(db, user.id, request.app.state.storage)

    def chunks():
        try:
            while block := archive.read(65536):
                yield block
        finally:
            archive.close()

    return StreamingResponse(
        chunks(),
        media_type="application/zip",
        headers={
            "Content-Disposition": 'attachment; filename="aibs-data.zip"',
            "Cache-Control": "no-store",
        },
        background=BackgroundTask(archive.close),
    )


@router.delete("", status_code=204)
def delete(
    request: Request,
    confirm: bool = Query(False),
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    if not confirm:
        raise ApiError(422, "confirmation_required", "Konfirmasi penghapusan data terlebih dahulu.")
    privacy.delete_data(db, user.id, request.app.state.storage)
    return Response(status_code=204)
