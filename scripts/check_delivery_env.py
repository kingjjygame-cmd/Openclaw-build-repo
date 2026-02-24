#!/usr/bin/env python3
"""Quick preflight checker for OpenClaw APK delivery loop."""

import os
import smtplib
import ssl

REQUIRED = ["GITHUB_TOKEN", "SMTP_HOST", "SMTP_USER", "SMTP_PASSWORD"]


def check(name, cond):
    return (name, bool(cond))


def main():
    print("[check] environment readiness")
    status = {name: bool(os.environ.get(name)) for name in REQUIRED}
    for k, ok in status.items():
        if k == "SMTP_PASSWORD":
            print(f"- {k}: {'(set)' if ok else 'MISSING'}")
        else:
            print(f"- {k}: {os.environ.get(k) if ok else 'MISSING'}")

    if not status["SMTP_HOST"]:
        os.environ["SMTP_HOST"] = "smtp.gmail.com"
        status["SMTP_HOST"] = True
        print("  -> defaulted SMTP_HOST to smtp.gmail.com")

    if not status["GITHUB_TOKEN"]:
        print("[FATAL] GITHUB_TOKEN missing")
    if not status["SMTP_USER"] or not status["SMTP_PASSWORD"]:
        print("[FATAL] SMTP_USER/SMTP_PASSWORD missing")

    if not all([status["GITHUB_TOKEN"], status["SMTP_USER"], status["SMTP_PASSWORD"]]):
        return 1

    smtp_host = os.environ["SMTP_HOST"]
    smtp_port = int(os.environ.get("SMTP_PORT", "465"))
    smtp_user = os.environ["SMTP_USER"]
    smtp_pw = os.environ["SMTP_PASSWORD"]

    print(f"[check] testing SMTP connect {smtp_host}:{smtp_port} user={smtp_user}")
    try:
        if smtp_port == 465:
            with smtplib.SMTP_SSL(smtp_host, smtp_port, context=ssl.create_default_context()) as s:
                s.login(smtp_user, smtp_pw)
        else:
            with smtplib.SMTP(smtp_host, smtp_port) as s:
                s.starttls(context=ssl.create_default_context())
                s.login(smtp_user, smtp_pw)
        print("[OK] SMTP auth works")
    except Exception as e:
        print(f"[ERROR] SMTP auth failed: {e}")
        return 2

    print("[OK] delivery environment is ready")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
