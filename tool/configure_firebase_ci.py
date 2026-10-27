"""Optional Android Firebase setup for GitHub Actions.

Reads FIREBASE_ANDROID_JSON_B64 from environment. Never prints its value.
"""
import os
import base64
from pathlib import Path

config = os.environ.get("FIREBASE_ANDROID_JSON_B64", "").strip()
if not config:
    print("Firebase not configured: offline PelajarKu build.")
else:
    raw = base64.b64decode(config, validate=True)
    if len(raw) > 128000 or b'"project_info"' not in raw:
        raise SystemExit("Invalid Firebase configuration JSON")
    Path("android/app/google-services.json").write_bytes(raw)

    settings = Path("android/settings.gradle.kts")
    source = settings.read_text()
    declaration = '    id("com.google.gms.google-services") version "4.4.4" apply false\n'
    if declaration not in source:
        anchor = 'plugins {'
        if anchor not in source:
            raise SystemExit("Gradle settings plugins block not found")
        source = source.replace(anchor, anchor + "\n" + declaration, 1)
    settings.write_text(source)

    app = Path("android/app/build.gradle.kts")
    source = app.read_text()
    plugin = '    id("com.google.gms.google-services")\n'
    if plugin not in source:
        if 'plugins {' not in source:
            raise SystemExit("Android app plugins block not found")
        source = source.replace('plugins {', 'plugins {\n' + plugin, 1)
    app.write_text(source)
    print("Firebase Android configuration injected securely.")
