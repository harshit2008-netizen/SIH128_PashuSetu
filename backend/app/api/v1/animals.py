"""Herds, animals and vaccinations (spec 8.2, P1): the records behind "vaccine due" reminders.

Farmers see their own herds; pashu sevaks every herd in their block, and they
record vaccinations, including "Vaccinated today" for a whole herd in one call.
"""

import re
import uuid
from datetime import date, timedelta

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.api.v1.reports import VACCINATION_DUE_DAYS, my_herds_filter
from app.core.db import get_db
from app.core.errors import AppError
from app.core.security import require_roles
from app.core.shared_loader import get_shared_data
from app.models import Animal, Herd, User, Vaccination, Village
from app.services.cases import utcnow

router = APIRouter(tags=["animals"])
KEEPERS = ("farmer", "pashu_sevak")
EAR_TAG = re.compile(r"^\d{12}$")


class AnimalIn(BaseModel):
    herd_id: uuid.UUID
    species: str
    ear_tag: str | None = Field(None, description="12-digit ear tag, if the animal has one")
    name: str | None = Field(None, max_length=64)
    breed: str | None = Field(None, max_length=64)
    sex: str | None = Field(None, pattern="^(female|male)$")
    age_months: int | None = Field(None, ge=0, le=400)

    @field_validator("ear_tag")
    @classmethod
    def twelve_digits(cls, value: str | None) -> str | None:
        if value is not None and not EAR_TAG.match(value):
            raise ValueError("An ear tag has exactly 12 digits.")
        return value


class VaccinationIn(BaseModel):
    vaccine: str = Field(description="Vaccine id from shared/vaccines.json, e.g. FMD")
    given_on: date | None = Field(None, description="Defaults to today")


def today() -> date:
    return utcnow().date()


def my_herd(db: Session, user: User, herd_id: uuid.UUID) -> Herd:
    herd = db.scalar(select(Herd).where(Herd.id == herd_id, my_herds_filter(user)))
    if herd is None:
        raise AppError(404, "herd_not_found", "No such herd in your area.")
    return herd


def check_vaccine(vaccine_id: str, species: str | None = None) -> dict:
    vaccine = get_shared_data().vaccines.get(vaccine_id)
    if vaccine is None:
        raise AppError(422, "unknown_vaccine", f"Unknown vaccine: {vaccine_id}")
    if species is not None and species not in vaccine["species"]:
        raise AppError(422, "vaccine_not_for_species", f"{vaccine_id} is not given to {species}.")
    return vaccine


def record(db: Session, animal: Animal, vaccine: dict, given_on: date, user: User) -> Vaccination:
    entry = Vaccination(animal_id=animal.id, herd_id=animal.herd_id, vaccine=vaccine["id"], given_on=given_on,
                        next_due_on=given_on + timedelta(days=vaccine["interval_days"]), given_by=user.id)
    db.add(entry)
    return entry


def vaccination_out(v: Vaccination) -> dict:
    return {"id": v.id, "vaccine": v.vaccine, "given_on": v.given_on, "next_due_on": v.next_due_on}


def next_due(vaccinations: list[Vaccination]) -> dict:
    """Per vaccine, only the latest dose counts; the soonest of those is "next due"."""
    latest: dict[str, Vaccination] = {}
    for v in sorted(vaccinations, key=lambda v: v.given_on):
        latest[v.vaccine] = v
    upcoming = sorted((v for v in latest.values() if v.next_due_on), key=lambda v: v.next_due_on)
    return {v.vaccine: v.next_due_on for v in upcoming}


def animal_out(animal: Animal, vaccinations: list[Vaccination]) -> dict:
    due = next_due(vaccinations)
    return {"id": animal.id, "herd_id": animal.herd_id, "ear_tag": animal.ear_tag, "name": animal.name,
            "species": animal.species, "breed": animal.breed, "sex": animal.sex, "age_months": animal.age_months,
            "vaccinations": [vaccination_out(v) for v in sorted(vaccinations, key=lambda v: v.given_on, reverse=True)],
            "next_due": [{"vaccine": k, "due_on": d, "overdue": d < today()} for k, d in due.items()]}


def vaccinations_by_animal(db: Session, animal_ids: list[uuid.UUID]) -> dict[uuid.UUID, list[Vaccination]]:
    grouped: dict[uuid.UUID, list[Vaccination]] = {a: [] for a in animal_ids}
    for v in db.scalars(select(Vaccination).where(Vaccination.animal_id.in_(animal_ids))):
        grouped[v.animal_id].append(v)
    return grouped


@router.get("/herds")
def herds(user: User = Depends(require_roles(*KEEPERS)), db: Session = Depends(get_db)):
    """My herds (sevak: every herd in the block), each with its animals and their next due vaccines."""
    rows = db.execute(select(Herd, Village).join(Village, Village.id == Herd.village_id)
                      .where(my_herds_filter(user)).order_by(Herd.name)).all()
    animals = db.scalars(select(Animal).where(Animal.herd_id.in_([h.id for h, _ in rows]))
                         .order_by(Animal.name, Animal.ear_tag)).all()
    vaccinations = vaccinations_by_animal(db, [a.id for a in animals])
    return [{"id": herd.id, "name": herd.name, "village": village.name,
             "animals": [animal_out(a, vaccinations[a.id]) for a in animals if a.herd_id == herd.id]}
            for herd, village in rows]


@router.get("/animals/{animal_id}")
def animal(animal_id: uuid.UUID, user: User = Depends(require_roles(*KEEPERS)), db: Session = Depends(get_db)):
    found = db.get(Animal, animal_id)
    if found is None:
        raise AppError(404, "animal_not_found", "No such animal.")
    my_herd(db, user, found.herd_id)
    return animal_out(found, vaccinations_by_animal(db, [found.id])[found.id])


@router.post("/animals")
def add_animal(body: AnimalIn, user: User = Depends(require_roles(*KEEPERS)), db: Session = Depends(get_db)):
    my_herd(db, user, body.herd_id)
    if body.species not in get_shared_data().species:
        raise AppError(422, "unknown_species", f"Unknown species: {body.species}")
    new = Animal(**body.model_dump())
    db.add(new)
    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise AppError(409, "ear_tag_taken", "Another animal already has this ear tag.") from error
    return animal_out(new, [])


@router.post("/animals/{animal_id}/vaccinations")
def vaccinate_animal(animal_id: uuid.UUID, body: VaccinationIn, user: User = Depends(require_roles("pashu_sevak")),
                     db: Session = Depends(get_db)):
    found = db.get(Animal, animal_id)
    if found is None:
        raise AppError(404, "animal_not_found", "No such animal.")
    my_herd(db, user, found.herd_id)
    record(db, found, check_vaccine(body.vaccine, found.species), body.given_on or today(), user)
    db.commit()
    return animal_out(found, vaccinations_by_animal(db, [found.id])[found.id])


@router.post("/herds/{herd_id}/vaccinations")
def vaccinate_herd(herd_id: uuid.UUID, body: VaccinationIn, user: User = Depends(require_roles("pashu_sevak")),
                   db: Session = Depends(get_db)):
    """"Vaccinated today" for the whole herd: every animal of a species the vaccine is for."""
    herd = my_herd(db, user, herd_id)
    vaccine = check_vaccine(body.vaccine)
    given_on = body.given_on or today()
    eligible = db.scalars(select(Animal).where(Animal.herd_id == herd.id, Animal.species.in_(vaccine["species"]))).all()
    if not eligible:
        raise AppError(422, "no_animals_for_vaccine", f"This herd has no animals that get {vaccine['id']}.")
    for a in eligible:
        record(db, a, vaccine, given_on, user)
    db.commit()
    return {"herd_id": herd.id, "vaccine": vaccine["id"], "given_on": given_on, "animals": len(eligible),
            "next_due_on": given_on + timedelta(days=vaccine["interval_days"])}


@router.get("/vaccinations/due")
def vaccinations_due(user: User = Depends(require_roles(*KEEPERS)), db: Session = Depends(get_db)):
    """Latest dose per animal and vaccine that is overdue or due within 30 days, soonest first."""
    animals = db.scalars(select(Animal).join(Herd, Animal.herd_id == Herd.id).where(my_herds_filter(user))).all()
    vaccinations = vaccinations_by_animal(db, [a.id for a in animals])
    horizon = today() + timedelta(days=VACCINATION_DUE_DAYS)
    due = [{"animal_id": a.id, "animal_name": a.name, "ear_tag": a.ear_tag, "species": a.species, "herd_id": a.herd_id,
            "vaccine": vaccine, "due_on": due_on, "overdue": due_on < today()}
           for a in animals for vaccine, due_on in next_due(vaccinations[a.id]).items() if due_on <= horizon]
    return sorted(due, key=lambda d: (d["due_on"], d["ear_tag"] or ""))
