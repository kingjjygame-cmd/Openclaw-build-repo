#!/usr/bin/env python3
"""Quick preflight checker for OpenClaw APK delivery loop (Gmail via gog CLI)."""

import os
import shutil
import subprocess

REQUIRED = ["GITHUB_TOKEN", "GOG_ACCOUNT", "GOG_KEYRING_PASSWORD"]


def main():
    print("[check] environment readiness")
    status = {name: bool(os.environ.get(name)) for name in REQUIRED}

    for k, ok in status.items():
        if k == "GOG_KEYRING_PASSWORD":
            print(f"- {k}: {'(set)' if ok else 'MISSING'}")
        else:
            print(f"- {k}: {os.environ.get(k) if ok else 'MISSING'}")

    if not status["GITHUB_TOKEN"]:
        print("[FATAL] GITHUB_TOKEN missing")
    if not status["GOG_ACCOUNT"]:
        print("[FATAL] GOG_ACCOUNT missing")
    if not status["GOG_KEYRING_PASSWORD"]:
        print("[WARN] GOG_KEYRING_PASSWORD not set; keyring access may fail in non-interactive mode")

    if not all([status["GITHUB_TOKEN"], status["GOG_ACCOUNT"]]):
        return 1

    if not shutil.which("gog"):
        print("[FATAL] 'gog' CLI not found in PATH")
        return 1

    account = os.environ["GOG_ACCOUNT"]
    cmd = [
        "gog",
        "auth",
        "list",
        "--json",
        "--check",
        "--no-input",
        f"--account={account}",
    ]
    print(f"[check] testing gog token for {account}")
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print(f"[ERROR] gog auth check failed: rc={proc.returncode}")
        print(proc.stdout.strip())
        print(proc.stderr.strip())
        print("Set GOG_KEYRING_PASSWORD and retry.")
        return 2

    print("[OK] Gmail delivery environment looks ready")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
