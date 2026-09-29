from tests.conftest import PHONES


def test_demo_accounts_list_one_per_role(client):
    accounts = client.get("/api/v1/auth/demo-accounts").json()
    assert [a["role"] for a in accounts] == ["farmer", "pashu_sevak", "vet", "lab", "district_officer"]


def test_otp_request_tells_the_demo_otp(client):
    body = client.post("/api/v1/auth/otp/request", json={"phone": PHONES["farmer"]}).json()
    assert body == {"sent": True, "demo_otp": "123456"}


def test_unknown_phone_gets_plain_error(client):
    response = client.post("/api/v1/auth/otp/request", json={"phone": "9111111111"})
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "unknown_phone"


def test_wrong_otp_is_rejected(client):
    response = client.post("/api/v1/auth/otp/verify", json={"phone": PHONES["vet"], "otp": "000000"})
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "wrong_otp"


def test_login_returns_token_and_profile_with_area(client, as_role):
    me = client.get("/api/v1/me", headers=as_role("pashu_sevak")).json()
    assert me["role"] == "pashu_sevak"
    assert me["block"]["code"] == "junnar"


def test_missing_token_is_401(client):
    response = client.get("/api/v1/me")
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "not_authenticated"


def test_role_guard_blocks_farmer_from_case_queue(client, as_role):
    response = client.get("/api/v1/cases", headers=as_role("farmer"))
    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"
