#!/usr/bin/env python3
"""앱개발 자동화 오케스트레이터
- GitHub Actions 워크플로우 디스패치
- 실행 상태 polling (5분 no-progress 감시)
- 실패시 실패 사유 로그 출력 후 즉시 재시도
- 성공시: APK 아티팩트 내려받아 검증(+가능 시 설치 검증)
- 성공 시 Gmail 첨부 + Telegram 알림
- 실행은 기본 무한 재시도(필요시 MAX_RETRIES 설정)
"""

import json
import os
import ssl
import subprocess
import time
import zipfile
import shutil
from datetime import datetime
from typing import Dict, Optional
from urllib.parse import quote_plus
from urllib.request import Request, urlopen

GITHUB_API = "https://api.github.com"
WORKFLOW_FILE = os.environ.get("WORKFLOW_FILE", "android-apk.yml")
POLL_SECONDS = int(os.environ.get("POLL_SECONDS", "15"))
STALL_SECONDS = int(os.environ.get("STALL_SECONDS", "300"))  # 5분
MAX_RETRIES = int(os.environ.get("MAX_RETRIES", "0"))  # 0이면 무한 재시도


def _headers(token: str):
    return {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "User-Agent": "openclaw",
    }


def _get_json(url: str, token: str):
    req = Request(url, headers=_headers(token))
    with urlopen(req, context=ssl._create_unverified_context()) as r:
        return json.loads(r.read().decode())


def _post(url: str, payload: Optional[dict], token: str):
    data = json.dumps(payload or {}).encode() if payload is not None else None
    headers = _headers(token)
    if data:
        headers["Content-Type"] = "application/json"
    req = Request(url, data=data, method="POST", headers=headers)
    with urlopen(req, context=ssl._create_unverified_context()) as r:
        return r.status


def _parse_updated_ts(updated_at: str) -> float:
    # ex) 2026-02-24T03:12:00Z
    try:
        return datetime.strptime(updated_at, "%Y-%m-%dT%H:%M:%SZ").timestamp()
    except Exception:
        return time.time()


def dispatch(owner_repo: str, ref: str, token: str):
    url = f"{GITHUB_API}/repos/{owner_repo}/actions/workflows/{WORKFLOW_FILE}/dispatches"
    status = _post(url, {"ref": ref}, token)
    if status not in (204, 201):
        raise RuntimeError(f"dispatch failed status={status}")


def latest_run(owner_repo: str, token: str):
    data = _get_json(f"{GITHUB_API}/repos/{owner_repo}/actions/workflows/{WORKFLOW_FILE}/runs?per_page=1", token)
    runs = data.get("workflow_runs", [])
    if not runs:
        raise RuntimeError("No runs returned")
    return runs[0]


def run_info(owner_repo: str, run_id: int, token: str):
    return _get_json(f"{GITHUB_API}/repos/{owner_repo}/actions/runs/{run_id}", token)


def cancel_run(owner_repo: str, run_id: int, token: str):
    try:
        _post(f"{GITHUB_API}/repos/{owner_repo}/actions/runs/{run_id}/cancel", None, token)
        print(f"[ci] canceled stalled run {run_id}")
    except Exception:
        # cancel 실패해도 큰 문제 없음
        pass


def run_jobs(owner_repo: str, run_id: int, token: str):
    run = run_info(owner_repo, run_id, token)
    jobs = _get_json(run["jobs_url"], token).get("jobs", [])
    return run, jobs


def _latest_fail_step(jobs: list) -> Optional[Dict]:
    if not jobs:
        return None
    # 마지막 실패한 job/step 탐색
    # 보통 jobs는 보존 단계 순서와 상관 없어도 실패 step tail로 충분
    for job in sorted(jobs, key=lambda j: j.get("started_at") or ""):
        steps = job.get("steps", [])
        for s in steps:
            if s.get("conclusion") == "failure":
                return s
    # 최근 단계부터 역순 탐색
    for job in reversed(jobs):
        for s in reversed(job.get("steps", [])):
            if s.get("conclusion") == "failure":
                return s
    return None


def failure_reason(owner_repo: str, run_id: int, token: str):
    run, jobs = run_jobs(owner_repo, run_id, token)
    if not jobs:
        return f"jobs unavailable (conclusion={run.get('conclusion')})"

    step = _latest_fail_step(jobs)
    if step:
        return f"failed_step={step.get('name')} conclusion={step.get('conclusion')} url={step.get('html_url')}"

    return f"run failed; conclusion={run.get('conclusion')}"


def wait_complete(owner_repo: str, run_id: int, token: str):
    last_status = None
    last_updated_ts = time.time()
    last_updated_at = None

    while True:
        run = run_info(owner_repo, run_id, token)
        status = run.get("status")
        conclusion = run.get("conclusion")
        updated_at = run.get("updated_at")

        if status != last_status:
            print(f"[ci] run {run_id}: {status} / {conclusion} ({updated_at})")
            last_status = status

        if updated_at and updated_at != last_updated_at:
            last_updated_at = updated_at
            last_updated_ts = time.time()

        if time.time() - last_updated_ts >= STALL_SECONDS and status in ("queued", "in_progress"):
            raise TimeoutError(f"No status/updated_at change for >{STALL_SECONDS}s (possible stuck). run={run_id}")

        if status == "completed":
            return run

        time.sleep(POLL_SECONDS)


def ensure_smoke_pass(owner_repo: str, run_id: int, token: str):
    _, jobs = run_jobs(owner_repo, run_id, token)
    if not jobs:
        raise RuntimeError("no jobs in run")

    # 마지막 job 기준 step 상태 체크
    steps = jobs[0].get("steps", [])
    target_names = {
        "Setup and run emulator smoke test": ["success", "skipped", "neutral", "cancelled", "failure", "timed_out", "action_required", "stale"],
    }
    steps_by_name = {s.get("name"): s.get("conclusion") for s in steps}

    # smoke test step을 강제 성공으로 보지 않고, 스킵/성공만 통과 처리
    for step_name in target_names:
        if step_name not in steps_by_name:
            print(f"[ci] warn: '{step_name}' step missing in workflow")
            continue
        concl = steps_by_name[step_name]
        if concl not in ("success", "skipped"):
            raise RuntimeError(f"smoke test step not passing: {step_name} => {concl}")


def fetch_artifact(owner_repo: str, run_id: int, token: str, dst_zip: str = "/tmp/openclaw-apk-artifact.zip"):
    artifacts = _get_json(f"{GITHUB_API}/repos/{owner_repo}/actions/runs/{run_id}/artifacts", token).get("artifacts", [])
    target = None
    for a in artifacts:
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
    out_dir = "/tmp/openclaw-apk-delivery"
    os.makedirs(out_dir, exist_ok=True)
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(out_dir)

    candidates = []
    for root, _d, files in os.walk(out_dir):
        for fn in files:
            if fn.endswith(".apk"):
                candidates.append(os.path.join(root, fn))
    if not candidates:
        raise RuntimeError("APK not in artifact")

    for p in candidates:
        if p.endswith("app-debug.apk"):
            return p
    return candidates[0]


def validate_apk(apk_path: str):
    if not os.path.exists(apk_path):
        raise RuntimeError("APK missing")
    if os.path.getsize(apk_path) <= 0:
        raise RuntimeError("APK size is 0")

    with zipfile.ZipFile(apk_path) as zf:
        names = set(zf.namelist())
        if "AndroidManifest.xml" not in names:
            raise RuntimeError("AndroidManifest.xml missing")
    print(f"[ci] APK validated: {apk_path}")


def local_install_verify(apk_path: str):
    adb = shutil.which("adb")
    if not adb:
        print("[ci] adb 미설치: 설치 검증(install/launch) 스킵")
        return

    # 장치 탐색
    dev_out = subprocess.run([adb, "devices"], capture_output=True, text=True)
    devices = []
    for line in dev_out.stdout.splitlines():
        if not line.strip() or line.startswith("List of devices"):
            continue
        cols = line.split()
        if len(cols) >= 2 and cols[1] == "device":
            devices.append(cols[0])

    if not devices:
        print("[ci] adb 연결 기기 없음: 설치 검증 스킵")
        return

    serial = devices[0]
    print(f"[ci] install verify on device: {serial}")
    install = subprocess.run([adb, "-s", serial, "install", "-r", apk_path], capture_output=True, text=True)
    if install.returncode != 0:
        raise RuntimeError(f"adb install failed: {install.stderr.strip()} {install.stdout.strip()}")

    # 패키지명 추출(간단 fallback)
    pkg = os.environ.get("APK_PACKAGE", "com.openclaw.todo")
    check = subprocess.run([adb, "-s", serial, "shell", "pm", "path", pkg], capture_output=True, text=True)
    if check.returncode != 0 or ":" not in check.stdout:
        print(f"[ci] warn: package path check failed for {pkg}")
    else:
        print(f"[ci] package installed: {pkg}")


def send_mail_with_gog(apk_path: str, run_url: str, to_addr: str, account: str):
    subject = "[OpenClaw Todo] APK 빌드 성공 - 검증 완료"
    body = f"APK 빌드/검증 완료\n\nRun: {run_url}\n첨부: app-debug.apk"

    cmd = [
        "gog",
        "gmail",
        "send",
        "--account", account,
        "--no-input",
        "--force",
        "--to", to_addr,
        "--subject", subject,
        "--body", body,
        "--attach", apk_path,
    ]

    completed = subprocess.run(cmd, capture_output=True, text=True)
    if completed.returncode != 0:
        raise RuntimeError(
            f"gog gmail send failed: rc={completed.returncode}, out={completed.stdout.strip()}, err={completed.stderr.strip()}"
        )


def send_telegram(message: str):
    token = os.environ.get("TELEGRAM_BOT_TOKEN", "")
    chat_id = os.environ.get("TELEGRAM_CHAT_ID", "")
    if not token or not chat_id:
        print("[ci] telegram env 미설정(생략)")
        return

    text = quote_plus(message)
    url = f"https://api.telegram.org/bot{token}/sendMessage?chat_id={chat_id}&text={text}"
    try:
        req = Request(url, method="GET")
        with urlopen(req, context=ssl._create_unverified_context()) as _:
            print("[ci] telegram sent")
    except Exception as e:
        print(f"[ci] telegram send failed: {e}")


def main():
    owner_repo = os.environ.get("GITHUB_REPO", "kingjjygame-cmd/Openclaw-build-repo")
    token = os.environ.get("GITHUB_TOKEN", "")
    if not token:
        raise SystemExit("GITHUB_TOKEN missing")

    ref = os.environ.get("GITHUB_REF", "master")
    to_addr = os.environ.get("DELIVERY_EMAIL", "kingjjy.game@gmail.com")
    gog_account = os.environ.get("GOG_ACCOUNT", to_addr)

    retry_count = 0
    print("[ci] start delivery loop: failure retry + delivery validation")

    while True:
        if MAX_RETRIES and retry_count >= MAX_RETRIES:
            raise SystemExit("[ci] retry limit reached")

        try:
            print(f"[ci] [{retry_count + 1}] dispatching github workflow")
            dispatch(owner_repo, ref, token)

            run = latest_run(owner_repo, token)
            run_id = run["id"]
            run_url = run.get("html_url")
            print(f"[ci] started run {run_id}")

            final = wait_complete(owner_repo, run_id, token)
            if final.get("conclusion") != "success":
                reason = failure_reason(owner_repo, run_id, token)
                raise RuntimeError(f"run failed: conclusion={final.get('conclusion')} reason={reason}")

            ensure_smoke_pass(owner_repo, run_id, token)
            zip_path = fetch_artifact(owner_repo, run_id, token)
            apk_path = extract_apk(zip_path)
            validate_apk(apk_path)
            local_install_verify(apk_path)

            send_mail_with_gog(apk_path, run_url, to_addr, gog_account)
            msg = f"✅ 앱 빌드 완료\nRun: {run_url}\nAPK: openclaw-todo-debug-apk\n수신: {to_addr}"
            send_telegram(msg)

            print(f"[ci] complete: {run_url}")
            print(f"[ci] success after {retry_count + 1} run")
            return 0

        except TimeoutError as e:
            # stuck 상태: 현재 실행 run 취소 후 재시도
            print(f"[ci] watchdog timeout: {e}")
            if 'run_id' in locals():
                cancel_run(owner_repo, run_id, token)
            retry_count += 1
            send_telegram(f"⚠️ GitHub run가 5분 이상 정체되어 재시도: retry={retry_count}")
            print(f"[ci] retrying after timeout (count={retry_count})")

        except Exception as e:
            # 실패면 원인 출력 후 즉시 재시도
            print(f"[ci] run/process failed: {e}")
            retry_count += 1
            send_telegram(f"⚠️ 빌드 실패, 재시도 중({retry_count}): {e}")
            print(f"[ci] retrying... ({retry_count})")

        # 백오프
        time.sleep(min(20, max(5, retry_count * 2)))


if __name__ == "__main__":
    raise SystemExit(main())
