from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_read_root():
    """Teste básico de health check"""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "order-service OK"}
