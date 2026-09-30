"""Find groups of nearby reports (spec 8.4). Pure functions, no database.

DBSCAN with the haversine metric works on the earth's surface directly:
eps is the radius in radians (km / 6371), so "5 km" means 5 km anywhere.
"""

import math
from collections.abc import Sequence
from dataclasses import dataclass

import numpy as np
from shapely.geometry import MultiPoint, Polygon
from sklearn.cluster import DBSCAN

EARTH_RADIUS_KM = 6371.0
# The alert area is the hull of the reports plus this margin, so a single
# village's reports still draw a visible area on the map.
AREA_MARGIN_M = 1000.0


@dataclass(frozen=True)
class LatLng:
    lat: float
    lng: float


def find_clusters(points: Sequence[LatLng], radius_km: float, min_reports: int) -> list[list[int]]:
    """Indices of the points in each cluster; noise points are left out."""
    if len(points) < min_reports:
        return []
    coords = np.radians([[p.lat, p.lng] for p in points])
    labels = DBSCAN(eps=radius_km / EARTH_RADIUS_KM, min_samples=min_reports,
                    metric="haversine", algorithm="ball_tree").fit(coords).labels_
    clusters: dict[int, list[int]] = {}
    for index, label in enumerate(labels):
        if label >= 0:
            clusters.setdefault(int(label), []).append(index)
    return list(clusters.values())


def haversine_km(a: LatLng, b: LatLng) -> float:
    lat1, lng1, lat2, lng2 = map(math.radians, (a.lat, a.lng, b.lat, b.lng))
    h = (math.sin((lat2 - lat1) / 2) ** 2
         + math.cos(lat1) * math.cos(lat2) * math.sin((lng2 - lng1) / 2) ** 2)
    return 2 * EARTH_RADIUS_KM * math.asin(math.sqrt(h))


def centroid(points: Sequence[LatLng]) -> LatLng:
    return LatLng(sum(p.lat for p in points) / len(points), sum(p.lng for p in points) / len(points))


def area_around(points: Sequence[LatLng], margin_m: float = AREA_MARGIN_M) -> Polygon:
    """Convex hull of the points plus a margin, as a lat/lng polygon.

    Buffering needs metres, so points are projected onto a flat plane around
    their centre first (accurate to well under 1% over a few tens of km).
    """
    centre = centroid(points)
    m_per_deg_lat = 111_320.0
    m_per_deg_lng = 111_320.0 * math.cos(math.radians(centre.lat))
    flat = MultiPoint([((p.lng - centre.lng) * m_per_deg_lng, (p.lat - centre.lat) * m_per_deg_lat) for p in points])
    shape = flat.convex_hull.buffer(margin_m, quad_segs=8)
    return Polygon([(centre.lng + x / m_per_deg_lng, centre.lat + y / m_per_deg_lat) for x, y in shape.exterior.coords])
