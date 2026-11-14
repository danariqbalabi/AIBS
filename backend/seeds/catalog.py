from uuid import NAMESPACE_URL, uuid5

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import make_engine
from app.models.entities import Ingredient, Menu, MenuIngredient

SOURCE = "Data sintetis tim AIBS untuk demo; bukan validasi nutrisi atau klinis."


def stable_id(key: str):
    return uuid5(NAMESPACE_URL, "https://aibs.demo/" + key)


INGREDIENTS = {
    "rice": ("Nasi putih", ["nasi"]),
    "chicken": ("Ayam", ["ayam paha"]),
    "garlic": ("Bawang putih", []),
    "onion": ("Bawang bombay", []),
    "shrimp": ("Udang", []),
    "peanut": ("Kacang tanah", []),
    "tofu": ("Tahu", []),
    "carrot": ("Wortel", []),
    "coconut": ("Santan", []),
    "ginger": ("Jahe", []),
    "milk": ("Susu sapi", ["susu"]),
    "wheat": ("Gandum", []),
    "egg": ("Telur", []),
    "fish": ("Ikan", []),
    "soy": ("Kedelai", []),
    "shellfish": ("Kerang", []),
    "fried": ("Gorengan", ["makanan berminyak"]),
    "coffee": ("Kopi", []),
    "soda": ("Soda", []),
    "skin": ("Kulit ayam", []),
    "fruit": ("Buah", []),
    "bread": ("Roti", []),
}

MENUS = [
    (
        "chicken-rice",
        "Nasi ayam jahe",
        "buy",
        22000,
        ["halal"],
        ["low_fodmap", "low_fat"],
        [("rice", 1, "porsi"), ("chicken", 100, "g"), ("ginger", 5, "g")],
    ),
    (
        "tofu-carrot",
        "Tahu wortel",
        "cook",
        15000,
        ["vegetarian", "halal", "quick"],
        ["low_fodmap", "low_fat"],
        [("tofu", 80, "g"), ("carrot", 80, "g")],
    ),
    (
        "shrimp-rice",
        "Nasi udang",
        "buy",
        24000,
        ["halal"],
        ["low_fat"],
        [("rice", 1, "porsi"), ("shrimp", 80, "g")],
    ),
    (
        "peanut-tofu",
        "Tahu saus kacang",
        "buy",
        18000,
        ["vegetarian", "halal"],
        ["low_fodmap"],
        [("tofu", 80, "g"), ("peanut", 20, "g")],
    ),
    (
        "garlic-rice",
        "Nasi ayam bawang",
        "buy",
        18000,
        ["halal"],
        ["low_fat"],
        [("rice", 1.5, "porsi"), ("chicken", 100, "g"), ("garlic", 5, "g")],
    ),
    (
        "coconut-chicken",
        "Ayam santan",
        "cook",
        20000,
        ["halal"],
        [],
        [("chicken", 100, "g"), ("coconut", 50, "ml"), ("garlic", 5, "g")],
    ),
]

MENU_DETAILS = {
    "chicken-rice": (
        15,
        "Konfirmasi ayam tidak dimarinasi bawang. Minta jahe tanpa saus tambahan; nasi 1 porsi. "
        "Tanyakan bumbu dan kemungkinan kontak dengan alergen.",
    ),
    "tofu-carrot": (
        15,
        "Potong tahu dan wortel. Masak dengan sedikit air hingga matang, "
        "tanpa menambahkan saus atau bumbu yang belum dikonfirmasi. "
        "Sesuaikan porsi dengan arahanmu.",
    ),
    "shrimp-rice": (
        15,
        "Konfirmasi bumbu udang dan cara pengolahan. Pesan nasi 1 porsi. "
        "Menu mengandung udang; periksa alergi sebelum memilih.",
    ),
    "peanut-tofu": (
        15,
        "Tanyakan seluruh bahan saus kacang dan bumbu tahu. "
        "Pisahkan saus agar porsinya dapat dikonfirmasi. Menu mengandung kacang tanah.",
    ),
    "garlic-rice": (
        20,
        "Konfirmasi bawang putih pada ayam dan bumbunya. Nasi contoh 1,5 porsi; "
        "ubah jumlah dan cek ulang bila arahanmu membatasi porsi.",
    ),
    "coconut-chicken": (
        25,
        "Masak ayam sampai matang bersama santan dan bawang putih sesuai komposisi contoh. "
        "Konfirmasi seluruh bumbu tambahan dan cek arahanmu sebelum memilih.",
    ),
}


def seed_catalog(session: Session):
    for key, (name, aliases) in INGREDIENTS.items():
        session.merge(Ingredient(id=stable_id(key), name=name, aliases=aliases, source=SOURCE))
    session.flush()
    for key, name, kind, price, tags, directives, ingredients in MENUS:
        minutes, instructions = MENU_DETAILS[key]
        tags = [*tags, "no_red_meat", "spicy_none", f"minutes_{minutes}"]
        if minutes <= 15 and "quick" not in tags:
            tags.append("quick")
        session.merge(
            Menu(
                id=stable_id(key),
                name=name,
                kind=kind,
                price_rupiah=price,
                tags=tags,
                directives=directives,
                ingredients_complete=True,
                instructions=instructions,
                source=SOURCE,
            )
        )
        session.flush()
        for ingredient, quantity, unit in ingredients:
            session.merge(
                MenuIngredient(
                    menu_id=stable_id(key),
                    ingredient_id=stable_id(ingredient),
                    quantity=quantity,
                    unit=unit,
                )
            )
    session.flush()


if __name__ == "__main__":
    with Session(make_engine(get_settings())) as session, session.begin():
        seed_catalog(session)
    print("Synthetic catalog seeded.")
