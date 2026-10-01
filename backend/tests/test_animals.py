"""Herd and animal records, vaccinations and "due" reminders (P1)."""

from datetime import date, timedelta

from app.core.shared_loader import get_shared_data

VACCINES = get_shared_data().vaccines


def first_cattle_herd(client, headers):
    herds = client.get("/api/v1/herds", headers=headers).json()
    return next(h for h in herds if any(a["species"] == "cattle" for a in h["animals"]))


def test_farmer_sees_own_herds_and_sevak_sees_the_block(client, as_role):
    farmer = client.get("/api/v1/herds", headers=as_role("farmer")).json()
    sevak = client.get("/api/v1/herds", headers=as_role("pashu_sevak")).json()
    assert farmer and len(sevak) > len(farmer)
    assert {h["id"] for h in farmer} <= {h["id"] for h in sevak}
    assert client.get("/api/v1/herds", headers=as_role("vet")).status_code == 403


def test_vaccinated_today_for_a_whole_herd(client, as_role):
    sevak = as_role("pashu_sevak")
    herd = first_cattle_herd(client, sevak)
    cattle = [a for a in herd["animals"] if a["species"] in VACCINES["HS"]["species"]]
    response = client.post(f"/api/v1/herds/{herd['id']}/vaccinations", json={"vaccine": "HS"}, headers=sevak)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["animals"] == len(cattle)
    assert body["next_due_on"] == (date.today() + timedelta(days=VACCINES["HS"]["interval_days"])).isoformat()
    profile = client.get(f"/api/v1/animals/{cattle[0]['id']}", headers=sevak).json()
    assert profile["vaccinations"][0]["vaccine"] == "HS"
    assert {"vaccine": "HS", "due_on": body["next_due_on"], "overdue": False} in profile["next_due"]


def test_wrong_vaccine_or_species_is_refused(client, as_role):
    sevak = as_role("pashu_sevak")
    herd = first_cattle_herd(client, sevak)
    cow = next(a for a in herd["animals"] if a["species"] == "cattle")
    assert client.post(f"/api/v1/animals/{cow['id']}/vaccinations", json={"vaccine": "PPR"},
                       headers=sevak).json()["error"]["code"] == "vaccine_not_for_species"
    assert client.post(f"/api/v1/herds/{herd['id']}/vaccinations", json={"vaccine": "XYZ"},
                       headers=sevak).status_code == 422
    assert client.post(f"/api/v1/herds/{herd['id']}/vaccinations", json={"vaccine": "HS"},
                       headers=as_role("farmer")).status_code == 403


def test_add_an_animal_with_a_valid_ear_tag(client, as_role):
    farmer = as_role("farmer")
    herd = client.get("/api/v1/herds", headers=farmer).json()[0]
    body = {"herd_id": herd["id"], "species": "cattle", "ear_tag": "123456789012", "name": "Chandra", "sex": "female"}
    created = client.post("/api/v1/animals", json=body, headers=farmer)
    assert created.status_code == 200, created.text
    assert client.post("/api/v1/animals", json=body, headers=farmer).json()["error"]["code"] == "ear_tag_taken"
    assert client.post("/api/v1/animals", json={**body, "ear_tag": "12AB"}, headers=farmer).status_code == 422


def test_due_list_is_soonest_first_and_includes_the_seeded_reminder(client, as_role):
    due = client.get("/api/v1/vaccinations/due", headers=as_role("farmer")).json()
    assert due, "the seed gives the demo farmer's first cow an FMD dose due in 13 days"
    assert [d["due_on"] for d in due] == sorted(d["due_on"] for d in due)
    horizon = (date.today() + timedelta(days=30)).isoformat()
    assert all(d["due_on"] <= horizon for d in due)
