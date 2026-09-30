import uuid
from datetime import date, datetime
from typing import Literal

from pydantic import AwareDatetime, BaseModel, Field, model_validator

from app.schemas.common import LatLng, Species


class TriageIn(BaseModel):
    """Stateless triage input (POST /triage/evaluate)."""

    species: Species
    symptoms: list[str] = Field(default_factory=list, examples=[["skin_nodules", "fever"]])
    sick_count: int = Field(0, ge=0)
    dead_count: int = Field(0, ge=0)
    total_at_risk: int | None = Field(None, ge=0)
    report_month: int = Field(ge=1, le=12, examples=[9])
    image_p_lsd: float | None = Field(None, ge=0, le=1, description="LSD probability from the phone's photo model")


class ReportIn(BaseModel):
    """One report from the phone. Matches the spec's POST /reports payload."""

    client_uuid: uuid.UUID = Field(description="Made on the phone; sending it twice never creates two reports")
    village_id: uuid.UUID | None = Field(None, description="If missing, the nearest village to `location` is used")
    location: LatLng
    species: Species
    symptoms: list[str] = Field(default_factory=list, examples=[["skin_nodules", "fever"]])
    sick_count: int = Field(0, ge=0, examples=[2])
    dead_count: int = Field(0, ge=0, examples=[0])
    total_at_risk: int | None = Field(None, ge=0, examples=[12])
    onset_date: date | None = None
    voice_transcript: str | None = Field(None, max_length=2000)
    herd_id: uuid.UUID | None = None
    animal_id: uuid.UUID | None = None
    device_triage: dict | None = Field(
        None, examples=[{"engine_version": "rules-1", "top": "lsd", "score": 0.72}],
        description="The phone's own triage result; `image_p_lsd` here is used for photo fusion")
    created_on_device_at: AwareDatetime
    channel: Literal["app", "sms", "ivr"] = "app"

    @model_validator(mode="after")
    def check_counts(self) -> "ReportIn":
        if not self.symptoms and self.dead_count < 1:
            raise ValueError("Choose at least one sign, or report a dead animal.")
        if self.total_at_risk is not None and self.total_at_risk < self.sick_count + self.dead_count:
            raise ValueError("Total animals cannot be less than sick plus dead.")
        # The photo probability changes the server's own score, so it must be a real probability.
        image_p = (self.device_triage or {}).get("image_p_lsd")
        if image_p is not None and (isinstance(image_p, bool) or not isinstance(image_p, int | float)
                                    or not 0 <= image_p <= 1):
            raise ValueError("device_triage.image_p_lsd must be a number from 0 to 1.")
        return self


class ReportOut(BaseModel):
    id: uuid.UUID
    client_uuid: uuid.UUID
    village_id: uuid.UUID
    location: LatLng
    species: str
    symptoms: list[str]
    sick_count: int
    dead_count: int
    total_at_risk: int | None
    onset_date: date | None
    voice_transcript: str | None
    has_photo: bool
    created_on_device_at: datetime
    received_at: datetime
    channel: str


class ReportResult(BaseModel):
    status: Literal["created", "duplicate"]
    report: ReportOut
    triage: dict
    case_id: uuid.UUID


class SyncPushIn(BaseModel):
    reports: list[ReportIn] = Field(max_length=50)


class SyncItemResult(BaseModel):
    client_uuid: uuid.UUID
    status: Literal["created", "duplicate", "error"]
    message: str | None = None
    report_id: uuid.UUID | None = None
    case_id: uuid.UUID | None = None


class SyncPushOut(BaseModel):
    results: list[SyncItemResult]
