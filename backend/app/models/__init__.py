"""All SQLAlchemy models. Importing this package registers every table on Base.metadata."""

from app.models.geo import Block, District, Village
from app.models.people import Animal, Herd, User, Vaccination
from app.models.reports import Case, CaseEvent, CaseReport, Report, TriageResult
from app.models.response import Advisory, AdvisoryRecipient, Alert, LabSample, RiskScore, WeatherCache

__all__ = [
    "Advisory", "AdvisoryRecipient", "Alert", "Animal", "Block", "Case", "CaseEvent", "CaseReport",
    "District", "Herd", "LabSample", "Report", "RiskScore", "TriageResult", "User", "Vaccination",
    "Village", "WeatherCache",
]
