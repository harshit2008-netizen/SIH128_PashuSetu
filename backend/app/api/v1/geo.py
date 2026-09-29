"""Villages and blocks for the report form and the officer map."""

from fastapi import APIRouter, Depends, Query
from geoalchemy2 import Geography
from sqlalchemy import cast, func, select
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.errors import AppError
from app.core.security import get_current_user
from app.models import Block, User, Village
from app.services.geo_utils import make_point, point_latlng

router = APIRouter(tags=["geo"])

METERS_PER_KM = 1000.0


def parse_near(near: str) -> tuple[float, float]:
    try:
        lat, lng = (float(part) for part in near.split(","))
    except ValueError as exc:
        raise AppError(422, "bad_near", "Use near=lat,lng, for example near=19.2,73.87.") from exc
    return lat, lng


def village_out(village: Village, block: Block, distance_km: float | None = None) -> dict:
    out = {"id": village.id, "code": village.code, "name": village.name,
           "block": {"id": block.id, "code": block.code, "name": block.name},
           **point_latlng(village.centroid)}
    if distance_km is not None:
        out["distance_km"] = distance_km
    return out


@router.get("/geo/villages")
def villages(near: str | None = Query(None, examples=["19.2,73.87"]), limit: int = Query(10, le=500),
             _: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Nearest villages to `near` (with distance in km), or every village when `near` is empty."""
    query = select(Village, Block).join(Block, Village.block_id == Block.id)
    if near is None:
        return [village_out(v, b) for v, b in db.execute(query.order_by(Block.code, Village.code)).all()]
    # Casting to geography makes PostGIS measure metres on the earth, not degrees.
    distance = func.ST_Distance(cast(Village.centroid, Geography), cast(make_point(*parse_near(near)), Geography))
    rows = db.execute(query.add_columns(distance).order_by(distance).limit(limit)).all()
    return [village_out(v, b, round(d / METERS_PER_KM, 2)) for v, b, d in rows]


@router.get("/geo/blocks")
def blocks(_: User = Depends(get_current_user), db: Session = Depends(get_db)):
    rows = db.scalars(select(Block).order_by(Block.code)).all()
    return [{"id": b.id, "code": b.code, "name": b.name, "centroid": point_latlng(b.centroid)} for b in rows]
