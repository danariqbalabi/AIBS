from app.rules.assessment import evaluate
from app.services.profiles import assessment_for, profile_for, require_basic, versioned_update


def access_for(db, owner):
    return evaluate(profile_for(db, owner), assessment_for(db, owner).answers)


def evaluate_and_save(db, owner):
    require_basic(db, owner)
    row = assessment_for(db, owner)
    result = access_for(db, owner)
    versioned_update(db, row, row.version, {"result": result})
    db.commit()
    return {**result, "assessment_version": row.version}
