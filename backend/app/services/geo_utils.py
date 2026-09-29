"""Small helpers to move between PostGIS points and {lat, lng}."""

from geoalchemy2.elements import WKTElement
from geoalchemy2.shape import to_shape

from app.models.base import SRID


def make_point(lat: float, lng: float) -> WKTElement:
    # WKT order is longitude first.
    return WKTElement(f"POINT({lng} {lat})", srid=SRID)


def point_latlng(geometry) -> dict | None:
    if geometry is None:
        return None
    point = to_shape(geometry)
    return {"lat": round(point.y, 6), "lng": round(point.x, 6)}
