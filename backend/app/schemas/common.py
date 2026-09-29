from typing import Literal

from pydantic import BaseModel, Field

Species = Literal["cattle", "buffalo", "goat", "sheep", "pig", "poultry"]
Severity = Literal["routine", "urgent", "emergency"]
Language = Literal["en", "hi", "mr"]


class LatLng(BaseModel):
    lat: float = Field(ge=-90, le=90, examples=[19.2])
    lng: float = Field(ge=-180, le=180, examples=[73.87])


class Localized(BaseModel):
    en: str
    hi: str | None = None
    mr: str | None = None
