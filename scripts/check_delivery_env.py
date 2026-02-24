#!/usr/bin/env python3
"""Quick preflight checker for OpenClaw APK delivery loop (Gmail via gog CLI)."""

import os
import shutil
import subprocess

REQUIRED = ["GITHUB_TOKEN"]
REQUIRE_GOG = os.environ.get("SEND_MAIL", "0").lower() in ("1", "true", "yes", "y")
REQUIRED_GOG = ["GOG_ACCOUNT", "GOG_KEYRING_PASSWORD"]


def main():
    print("[check] environment readiness")
    status = {name: bool(os.environ.get(name)) for name in REQUIRED}
    status_gog = {name: bool(os.environ.get(name)) for name in REQUIRED_GOG}

    for k, ok in status.items():
        if k == "GITHUB_TOKEN":
            print(f"- {k}: {os.environ.get(k) if ok else 'MISSING'}")

    telegram_token = bool(os.environ.get("TELEGRAM_BOT_TOKEN"))
    telegram_chat = bool(os.environ.get("TELEGRAM_CHAT_ID"))
    if telegram_token and telegram_chat:
        print('- TELEGRAM: configured')
    elif telegram_token or telegram_chat:
        print('- TELEGRAM: partially configured (both BOT_TOKEN and CHAT_ID required)')
    else:
        print('- TELEGRAM: not set (notifications will skip telegram)')

    if REQUIRE_GOG:
        for k, ok in status_gog.items():
            if k == "GOG_KEYRING_PASSWORD":
                print(f"- {k}: {'(set)' if ok else 'MISSING'}")
            else:
                print(f"- {k}: {os.environ.get(k) if ok else 'MISSING'}")

        if not status_gog["GOG_ACCOUNT"]:
            print("[FATAL] GOG_ACCOUNT missing")
        if not status_gog["GOG_KEYRING_PASSWORD"]:
            print("[WARN] GOG_KEYRING_PASSWORD not set; keyring access may fail in non-interactive mode")

        if not all([status_gog["GOG_ACCOUNT"]]):
            return 1
    else:
        print("[OK] SEND_MAIL disabled; skipping gmail preflight checks")

    if not all([status["GITHUB_TOKEN"]]):
        return 1

    if REQUIRE_GOG:
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
    else:
        print("[OK] preflight without Gmail passed")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

