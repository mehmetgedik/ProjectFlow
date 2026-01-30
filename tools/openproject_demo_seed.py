#!/usr/bin/env python3
"""
OpenProject'ta "Mobil Demo" projesi ve örnek epic/task yapısı oluşturur.
Mobil uygulama test ortamı için kullanılır.

Kimlik bilgileri sohbete veya repoya yazılmaz; sadece ortam değişkenleri
veya komut satırı ile verilir.

Kullanım:
  pip install requests
  set OPENPROJECT_URL=https://openproject.example.com
  set OPENPROJECT_API_KEY=your_api_key_here
  python tools/openproject_demo_seed.py

Veya:
  python tools/openproject_demo_seed.py --url https://openproject.example.com --api-key YOUR_KEY
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
from datetime import datetime, timedelta
from urllib.parse import urljoin

try:
    import requests
except ImportError:
    print("Gerekli: pip install requests", file=sys.stderr)
    sys.exit(1)

# Varsayılan proje
DEFAULT_PROJECT_NAME = "Mobil Demo"
DEFAULT_PROJECT_IDENTIFIER = "mobil-demo"
DEFAULT_PROJECT_DESCRIPTION = (
    "Mobil OpenProject uygulaması test ortamı. Bu projede örnek epic ve task'lar bulunur."
)

# Örnek epic'ler (başlık, açıklama)
EPICS = [
    (
        "Mobil uygulama v1 – Temel akışlar",
        "Giriş, proje seçimi, iş paketleri listesi ve detay ekranlarının tamamlanması. "
        "Bildirimler ve zaman kaydı bu epic kapsamındadır.",
    ),
    (
        "Bildirimler ve mesai hatırlatma",
        "OpenProject bildirimlerinin mobilde gösterilmesi, mesai hatırlatma tercihleri ve "
        "cihaz bildirim ayarları ile entegrasyon.",
    ),
    (
        "Work package hızlı güncellemeler",
        "Durum, atanan, tarih ve öncelik gibi alanların mobilde hızlıca güncellenebilmesi; "
        "yorum ekleme ve aktivite akışı.",
    ),
]

# Her epic için task'lar: (başlık, açıklama kısa)
TASKS_PER_EPIC = [
    ("Gereksinim ve kabul kriterlerini netleştir", "Ürün ve teknik dokümanlarda tanımla."),
    ("Tasarım / mockup onayı", "Ekran akışları ve UI onayı al."),
    ("Geliştirme ve birim testleri", "Kod ve test yazımı."),
    ("Code review ve QA", "İnceleme ve manuel test."),
    ("Demo ve dokümantasyon", "Stakeholder demo ve kullanım notları."),
]


def normalize_base_url(url: str) -> str:
    """Instance URL'den API base URL (api/v3 ile biter) üretir."""
    u = (url or "").strip().rstrip("/")
    if not u:
        raise ValueError("OPENPROJECT_URL boş olamaz.")
    if "/api/v3" in u:
        return u if u.endswith("/api/v3") else u.split("/api/v3")[0] + "/api/v3"
    return u + "/api/v3"


def api_headers(api_key: str, json_body: bool = False) -> dict:
    auth = base64.b64encode(f"apikey:{api_key}".encode()).decode()
    h = {"Accept": "application/hal+json", "Authorization": f"Basic {auth}"}
    if json_body:
        h["Content-Type"] = "application/json"
    return h


def check_response(r: requests.Response, msg: str = "İstek başarısız") -> None:
    if r.status_code in (401, 403):
        raise SystemExit(f"{msg}: Yetkisiz (HTTP {r.status_code}). API key ve yetkileri kontrol edin.")
    if r.status_code < 200 or r.status_code >= 300:
        raise SystemExit(f"{msg}: HTTP {r.status_code}\n{r.text}")


def elements(data: dict) -> list:
    emb = data.get("_embedded") or {}
    return emb.get("elements") or []


def main() -> None:
    parser = argparse.ArgumentParser(
        description="OpenProject'ta Mobil Demo projesi ve örnek epic/task oluşturur."
    )
    parser.add_argument(
        "--url",
        default=os.environ.get("OPENPROJECT_URL"),
        help="OpenProject instance URL (örn. https://openproject.example.com)",
    )
    parser.add_argument(
        "--api-key",
        default=os.environ.get("OPENPROJECT_API_KEY"),
        help="API key (Hesabim - API erisimi). Ortam: OPENPROJECT_API_KEY",
    )
    parser.add_argument(
        "--project-name",
        default=DEFAULT_PROJECT_NAME,
        help="Oluşturulacak proje adı",
    )
    parser.add_argument(
        "--project-identifier",
        default=DEFAULT_PROJECT_IDENTIFIER,
        help="Proje tanımlayıcı (URL için, boşluk içermez)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="API çağrısı yapmadan sadece yapılacakları yazdır",
    )
    args = parser.parse_args()

    url = (args.url or "").strip()
    api_key = (args.api_key or "").strip()
    if args.dry_run:
        base = normalize_base_url(url or "https://openproject.example.com")
        print(f"[DRY-RUN] API base: {base}")
        print(f"[DRY-RUN] Proje: {args.project_name} ({args.project_identifier})")
        print("[DRY-RUN] Epic sayisi:", len(EPICS))
        print("[DRY-RUN] Her epic altinda task sayisi:", len(TASKS_PER_EPIC))
        return
    if not url or not api_key:
        print(
            "OPENPROJECT_URL ve OPENPROJECT_API_KEY gerekli.\n"
            "Ortam degiskeni: set OPENPROJECT_URL=... set OPENPROJECT_API_KEY=...\n"
            "Veya: --url ... --api-key ...",
            file=sys.stderr,
        )
        sys.exit(1)

    base = normalize_base_url(url)

    session = requests.Session()
    session.headers.update(api_headers(api_key))

    # 1) Proje oluştur
    project_payload = {
        "name": args.project_name,
        "identifier": args.project_identifier,
        "description": {"raw": DEFAULT_PROJECT_DESCRIPTION},
        "active": True,
        "public": False,
    }
    r = session.post(
        f"{base}/projects",
        headers=api_headers(api_key, json_body=True),
        json=project_payload,
        timeout=30,
    )
    check_response(r, "Proje oluşturma")
    project = r.json()
    project_id = str(project.get("id"))
    print(f"Proje oluşturuldu: {project.get('name')} (id={project_id})")

    # 2) Proje tipleri (Epic, Task)
    r = session.get(f"{base}/projects/{project_id}/types", timeout=30)
    check_response(r, "Proje tipleri")
    types_data = r.json()
    type_list = elements(types_data)
    type_by_name = {}
    for t in type_list:
        if isinstance(t, dict):
            tid = t.get("id")
            name = (t.get("name") or "").strip()
            if tid is not None and name:
                type_by_name[name.lower()] = str(tid)

    epic_type_id = (
        type_by_name.get("epic")
        or type_by_name.get("phase")
        or (type_list[0]["id"] if type_list else None)
    )
    task_type_id = type_by_name.get("task") or type_by_name.get("görev")
    if not task_type_id and type_list:
        for t in type_list:
            if isinstance(t, dict) and str(t.get("id")) != str(epic_type_id):
                task_type_id = str(t["id"])
                break
    if not task_type_id and type_list:
        task_type_id = str(type_list[0]["id"])
    if not epic_type_id:
        epic_type_id = task_type_id
    if not epic_type_id or not task_type_id:
        raise SystemExit("Bu projede kullanılabilir iş paketi tipi bulunamadı. Proje ayarlarından en az bir tip etkinleştirin.")

    # 3) Status ve öncelik
    r = session.get(f"{base}/statuses", timeout=30)
    check_response(r, "Status listesi")
    statuses = elements(r.json())
    status_id = str(statuses[0]["id"]) if statuses else None

    r = session.get(f"{base}/priorities", timeout=30)
    check_response(r, "Öncelik listesi")
    priorities = elements(r.json())
    priority_id = str(priorities[0]["id"]) if priorities else None

    def create_work_package(
        subject: str,
        type_id: str,
        description: str | None = None,
        parent_id: str | None = None,
        start_date: str | None = None,
        due_date: str | None = None,
    ) -> dict:
        links = {
            "project": {"href": f"/api/v3/projects/{project_id}"},
            "type": {"href": f"/api/v3/types/{type_id}"},
        }
        if status_id:
            links["status"] = {"href": f"/api/v3/statuses/{status_id}"}
        if priority_id:
            links["priority"] = {"href": f"/api/v3/priorities/{priority_id}"}
        if parent_id:
            links["parent"] = {"href": f"/api/v3/work_packages/{parent_id}"}
        body = {"subject": subject, "_links": links}
        if description:
            body["description"] = {"raw": description}
        if start_date:
            body["startDate"] = start_date
        if due_date:
            body["dueDate"] = due_date
        resp = session.post(
            f"{base}/work_packages",
            headers=api_headers(api_key, json_body=True),
            json=body,
            timeout=30,
        )
        check_response(resp, f"Work package oluşturma: {subject[:40]}...")
        return resp.json()

    today = datetime.now().date()
    epic_ids = []

    for i, (epic_title, epic_desc) in enumerate(EPICS):
        start = (today + timedelta(days=i * 14)).isoformat()
        due = (today + timedelta(days=i * 14 + 10)).isoformat()
        ep = create_work_package(
            epic_title,
            epic_type_id,
            description=epic_desc,
            start_date=start,
            due_date=due,
        )
        eid = str(ep["id"])
        epic_ids.append((eid, epic_title))
        print(f"  Epic: {epic_title} (id={eid})")

        for j, (task_title, task_desc) in enumerate(TASKS_PER_EPIC):
            t_start = (today + timedelta(days=i * 14 + j * 2)).isoformat()
            t_due = (today + timedelta(days=i * 14 + j * 2 + 1)).isoformat()
            tp = create_work_package(
                task_title,
                task_type_id,
                description=task_desc,
                parent_id=eid,
                start_date=t_start,
                due_date=t_due,
            )
            print(f"    Task: {task_title} (id={tp['id']})")

    origin = base.replace("/api/v3", "").rstrip("/")
    print()
    print("Bitti. Mobil uygulamada bağlanırken:")
    print(f"  Instance: {origin}")
    print(f"  Varsayılan proje: {args.project_name} (id={project_id})")
    print(f"  Proje URL: {origin}/projects/{args.project_identifier}")


if __name__ == "__main__":
    main()
