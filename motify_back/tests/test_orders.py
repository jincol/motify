import pytest
from datetime import datetime
from types import SimpleNamespace
from httpx import AsyncClient

from app.main import app
from app.api.v1.endpoints import order as order_module
from app.api import deps


@pytest.mark.asyncio
async def test_create_order_assigns_courier_and_returns_201(monkeypatch):
    # Fake create to avoid touching real DB
    async def fake_create(db, obj_in, extra=None):
        return SimpleNamespace(
            id=1,
            code="PED-TEST-0001",
            courier_id=(extra or {}).get("courier_id"),
            admin_id=(extra or {}).get("admin_id"),
            title=getattr(obj_in, 'title', None) or obj_in.get('title'),
            sender_name=getattr(obj_in, 'sender_name', None) or obj_in.get('sender_name'),
            sender_phone=getattr(obj_in, 'sender_phone', None) or obj_in.get('sender_phone'),
            description=getattr(obj_in, 'description', None) or obj_in.get('description'),
            instructions=getattr(obj_in, 'instructions', None) or obj_in.get('instructions'),
            status="pending",
            created_at=datetime.utcnow(),
            assigned_at=None,
            finished_at=None,
        )

    # Patch the crud_order used in the endpoint module
    monkeypatch.setattr(order_module, 'crud_order', SimpleNamespace(create=fake_create))

    # Override authentication dependency to return a motorizado user
    app.dependency_overrides[deps.get_current_user] = lambda: SimpleNamespace(id=131, role="motorizado")

    async with AsyncClient(app=app, base_url="http://test") as ac:
        payload = {"title": "Envio prueba", "sender_name": "Remitente X"}
        resp = await ac.post("/api/v1/orders/", json=payload)

    # Clean overrides
    app.dependency_overrides.clear()

    assert resp.status_code == 201
    data = resp.json()
    assert data["code"].startswith("PED-")
    assert data["courier_id"] == 131
