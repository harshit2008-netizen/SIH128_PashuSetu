"""`make seed` twice must give the same state (spec 8.10)."""

from sqlalchemy import text

from scripts import seed

SNAPSHOT = """SELECT md5(string_agg(x, '|' ORDER BY x)) FROM (
  SELECT 'u' || phone || name || role FROM users
  UNION ALL SELECT 'a' || coalesce(ear_tag, '-') || id FROM animals
  UNION ALL SELECT 'v' || animal_id || vaccine || next_due_on FROM vaccinations
  UNION ALL SELECT 'r' || client_uuid || array_to_string(symptoms, ',') || created_on_device_at FROM reports
  UNION ALL SELECT 'c' || c.status || c.severity || coalesce(c.suspected_disease, '-') || r.client_uuid
            FROM cases c JOIN reports r ON r.id = c.report_id) t(x)"""

NEARBY_SAME_SYNDROME_RECENT = """SELECT count(*) FROM reports a
  JOIN triage_results ta ON ta.report_id = a.id
  JOIN reports b ON b.id <> a.id JOIN triage_results tb ON tb.report_id = b.id
  WHERE a.created_on_device_at > now() - interval '14 days' AND b.created_on_device_at > now() - interval '14 days'
    AND ta.primary_syndrome = tb.primary_syndrome AND ta.primary_syndrome <> 'general'
    AND ST_DWithin(a.location::geography, b.location::geography, 5000)"""


def test_seed_twice_gives_the_same_state(db):
    summary = seed.run(db)
    first = db.execute(text(SNAPSHOT)).scalar()
    seed.run(db)
    assert db.execute(text(SNAPSHOT)).scalar() == first
    assert summary["villages"] == 68 and summary["herds"] >= 55 and summary["animals"] >= 240


def test_seed_leaves_no_active_cluster(db):
    seed.run(db)
    assert db.execute(text(NEARBY_SAME_SYNDROME_RECENT)).scalar() == 0
