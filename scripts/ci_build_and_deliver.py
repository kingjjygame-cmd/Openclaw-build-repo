#!/usr/bin/env python3
"""
Build retry loop:
- Trigger Android APK workflow
- On failure: extract failure reason and retry immediately
- On success: validate artifact + smoke result then send APK attachment by SMTP
- No retry limit (until user stops)
"""

import os
import sys
import json
import time
import zipfile
import ssl
import smtplib
from email.message import EmailMessage
from urllib.request import Request, urlopen

GITHUB_API = "https://api.github.com"
WORKFLOW_FILE = "android-apk.yml"
POLL_SECONDS = 15


def _headers(token: str):
    return {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "User-Agent": "openclaw",
    }


def _get_json(url, token):
    req = Request(url, headers=_headers(token))
    with urlopen(req, context=ssl._create_unverified_context()) as r:
        return json.loads(r.read().decode())


def _post(url, payload, token):
    payload_bytes = json.dumps(payload).encode()
    req = Request(url, data=payload_bytes, method="POST", headers={**_headers(token), "Content-Type": "application/json"})
    with urlopen(req, context=ssl._create_unverified_context()) as r:
        return r.status


def dispatch(owner_repo: str, ref: str, token: str):
    url = f"{GITHUB_API}/repos/{owner_repo}/actions/workflows/{WORKFLOW_FILE}/dispatches"
    status = _post(url, {"ref": ref}, token)
    if status not in (204, 201):
        raise RuntimeError(f"dispatch failed status={status}")


def latest_run(owner_repo: str, token: str):
    data = _get_json(f"{GITHUB_API}/repos/{owner_repo}/actions/workflows/{WORKFLOW_FILE}/runs?per_page=1", token)
    return data["workflow_runs"][0]


def get_run(url_base):
    return url_base


def run_info(owner_repo: str, run_id: int, token: str):
    return _get_json(f"{GITHUB_API}/repos/{owner_repo}/actions/runs/{run_id}", token)


def run_jobs(owner_repo: str, run_id: int, token: str):
    run = run_info(owner_repo, run_id, token)
    jobs = _get_json(run["jobs_url"], token)["jobs"]
    return run, jobs


def wait_complete(owner_repo: str, run_id: int, token: str):
    last = None
    while True:
        run = run_info(owner_repo, run_id, token)
        status = run.get("status")
        if status != last:
            print(f"[ci] run {run_id}: {status} / {run.get('conclusion')}")
            last = status
        if status == "completed":
            return run
        time.sleep(POLL_SECONDS)


def failure_reason(owner_repo: str, run_id: int, token: str):
    run, jobs = run_jobs(owner_repo, run_id, token)
    if not jobs:
        return "no jobs found"
    for s in jobs[0].get("steps", []):
        concl = s.get("conclusion")
        if concl == "failure":
            return f"failed step: {s.get('name')}, url={s.get('html_url')}"
    return f"run failed (conclusion={run.get('conclusion')})"


def ensure_smoke_pass(owner_repo: str, run_id: int, token: str):
    _, jobs = run_jobs(owner_repo, run_id, token)
    if not jobs:
        raise RuntimeError("no jobs in run")
    status_map = {s.get("name"): s.get("conclusion") for s in jobs[0].get("steps", [])}
    target = "Setup and run emulator smoke test"
    if target not in status_map:
        raise RuntimeError("smoke test step missing in workflow")
    if status_map[target] != "success":
        raise RuntimeError(f"smoke test failed: {status_map[target]}")


def fetch_artifact(owner_repo: str, run_id: int, token: str, dst_zip: str = "/tmp/openclaw-apk-artifact.zip"):
    arts = _get_json(f"{GITHUB_API}/repos/{owner_repo}/actions/runs/{run_id}/artifacts", token)["artifacts"]
    target = None
    for a in arts:
        if a.get("name") == "openclaw-todo-debug-apk":
            target = a
            break
    if not target:
        raise RuntimeError("artifact not found")

    req = Request(target["archive_download_url"], headers=_headers(token))
    with urlopen(req, context=ssl._create_unverified_context()) as r:
        with open(dst_zip, "wb") as f:
            f.write(r.read())
    return dst_zip


def extract_apk(zip_path: str):
    out = "/tmp/openclaw-apk-delivery"
    os.makedirs(out, exist_ok=True)
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(out)
    apks = []
    for root, _d, files in os.walk(out):
        for fn in files:
            if fn.endswith(".apk"):
                apks.append(os.path.join(root, fn))
    if not apks:
        raise RuntimeError("APK not in artifact")
    for p in apks:
        if p.endswith("app-debug.apk"):
            return p
    return apks[0]


def validate_apk(apk_path: str):
    if not os.path.exists(apk_path):
        raise RuntimeError("APK missing")
    if os.path.getsize(apk_path) <= 0:
        raise RuntimeError("APK size is 0")
    with zipfile.ZipFile(apk_path) as zf:
        if "AndroidManifest.xml" not in zf.namelist():
            raise RuntimeError("AndroidManifest.xml not found in APK")


def send_mail(apk_path: str, run_url: str, smtp_host: str, smtp_user: str, smtp_password: str, to_addr: str, smtp_port: int = 465, smtp_from: str = ""):
    sender = smtp_from or smtp_user
    msg = EmailMessage()
    msg["Subject"] = "[OpenClaw Todo] APK 빌드 성공 - 검증 완료"
    msg["From"] = sender
    msg["To"] = to_addr
    msg.set_content(f"APK 빌드/검증 완료\n\nRun: {run_url}\n첨부: 앱 APK")
    with open(apk_path, "rb") as f:
        data = f.read()
    msg.add_attachment(data, maintype="application", subtype="vnd.android.package-archive", filename=os.path.basename(apk_path))

    if smtp_port == 465:
        with smtplib.SMTP_SSL(smtp_host, smtp_port, context=ssl.create_default_context()) as s:
            s.login(smtp_user, smtp_password)
            s.send_message(msg)
    else:
        with smtplib.SMTP(smtp_host, smtp_port) as s:
            s.starttls(context=ssl.create_default_context())
            s.login(smtp_user, smtp_password)
            s.send_message(msg)


def main():
    owner_repo = os.environ.get("GITHUB_REPO", "kingjjygame-cmd/Openclaw-build-repo")
    token = os.environ.get("GITHUB_TOKEN", "")
    if not token:
        raise SystemExit("GITHUB_TOKEN missing")

    if not (smtp_host and smtp_user and smtp_pw):
        print("[FATAL] SMTP 환경 변수가 비었습니다. 아래를 설정하고 다시 실행하세요.")
        print("  export SMTP_HOST=smtp.gmail.com")
        print("  export SMTP_USER=your_email@gmail.com")
        print("  export SMTP_PASSWORD='gmail app password'")
        print("  export DELIVERY_EMAIL=kingjjy.game@gmail.com")
        print("  (선택) SMTP_FROM=your_email@gmail.com, SMTP_PORT=465")
        raise SystemExit(1)

    ref = os.environ.get("GITHUB_REF", "master")
    smtp_host = os.environ.get("SMTP_HOST", "")
    smtp_user = os.environ.get("SMTP_USER", "")
    smtp_pw = os.environ.get("SMTP_PASSWORD", "")
    smtp_port = int(os.environ.get("SMTP_PORT", "465"))
    smtp_from = os.environ.get("SMTP_FROM", "")
    to_addr = os.environ.get("DELIVERY_EMAIL", "kingjjy.game@gmail.com")

    print("[ci] start endless retry loop: failure retry + delivery success required")

    while True:
        print("[ci] dispatching github workflow")
        dispatch(owner_repo, ref, token)

        run = latest_run(owner_repo, token)
        run_id = run["id"]
        run_url = run.get("html_url")
        print(f"[ci] started run {run_id}")

        final = wait_complete(owner_repo, run_id, token)
        if final.get("conclusion") != "success":
            print(f"[ci] run {run_id} failed: {final.get('conclusion')}")
            print(f"[ci] reason: {failure_reason(owner_repo, run_id, token)}")
            print("[ci] re-run immediately")
            continue

        try:
            ensure_smoke_pass(owner_repo, run_id, token)
            zip_path = fetch_artifact(owner_repo, run_id, token)
            apk_path = extract_apk(zip_path)
            validate_apk(apk_path)

            print("[ci] apk 검증 완료")

            if not all([smtp_host, smtp_user, smtp_pw]):
                raise RuntimeError("SMTP env missing (SMTP_HOST/SMTP_USER/SMTP_PASSWORD)")

            send_mail(apk_path, run_url, smtp_host, smtp_user, smtp_pw, to_addr, smtp_port, smtp_from)
            print(f"[ci] mail sent to {to_addr}")
            print(f"[ci] complete: {run_url}")
            return 0
        except Exception as e:
            print(f"[ci] delivery/validation failed: {e}")
            print("[ci] retrying build")
            continue


if __name__ == "__main__":
    raise SystemExit(main())
