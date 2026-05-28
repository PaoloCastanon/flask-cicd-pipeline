import pytest
from app import create_app


@pytest.fixture()
def client():
    app = create_app()
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


class TestIndex:
    def test_status_ok(self, client):
        assert client.get("/").status_code == 200

    def test_returns_json(self, client):
        assert client.get("/").content_type == "application/json"

    def test_has_message_and_timestamp(self, client):
        data = client.get("/").get_json()
        assert "message" in data
        assert "timestamp" in data


class TestHealth:
    def test_status_ok(self, client):
        assert client.get("/health").status_code == 200

    def test_returns_healthy(self, client):
        assert client.get("/health").get_json() == {"status": "healthy"}


class TestVersion:
    def test_status_ok(self, client):
        assert client.get("/version").status_code == 200

    def test_has_version_key(self, client):
        data = client.get("/version").get_json()
        assert "version" in data
