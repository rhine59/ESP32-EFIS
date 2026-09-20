#!/usr/bin/env python3
"""Non-destructive functional harness for OTA admin logic.

Runs against a temporary OTA repository. It never reads or writes production
public/ data and requires no network access.
"""
import hashlib, importlib.util, io, json, os, pathlib, sys, tempfile

HERE=pathlib.Path(__file__).resolve().parent
APP=HERE/"app.py"

def check(ok,msg):
    if not ok: raise AssertionError(msg)
    print(f"PASS  {msg}")

with tempfile.TemporaryDirectory(prefix="efis-ota-test-") as td:
    root=pathlib.Path(td)
    efis=root/"efis"; (efis/"releases").mkdir(parents=True); (efis/"release-metadata").mkdir()
    original={"product":"ESP32-EFIS","version":"0.0.0","build":0,"image_url":"https://invalid.example/placeholder.bin","sha256":"PLACEHOLDER"}
    (efis/"manifest.json").write_text(json.dumps(original))

    os.environ["OTA_PUBLIC_ROOT"]=td
    os.environ["OTA_PUBLIC_BASE_URL"]="https://ota.test:8448"
    os.environ["ADMIN_SESSION_SECRET"]="functional-test-only"

    spec=importlib.util.spec_from_file_location("ota_admin_under_test",APP)
    mod=importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
    client=mod.app.test_client()

    r=client.get("/healthz"); check(r.status_code==200 and r.json=={"status":"ok"},"admin health endpoint")
    r=client.get("/"); check(r.status_code==200 and b"Firmware Administration" in r.data,"dashboard renders")

    image=(b"EFIS-TEST-IMAGE-"*100)
    digest=hashlib.sha256(image).hexdigest()
    r=client.post("/upload",data={
        "version":"9.9.9-test","build":"999","minimum":"0.0.0","notes":"Functional harness release",
        "firmware":(io.BytesIO(image),"test.bin")
    },content_type="multipart/form-data",follow_redirects=True)
    check(r.status_code==200 and b"9.9.9-test" in r.data,"firmware stages")
    check(json.loads((efis/"manifest.json").read_text())["version"]=="0.0.0","staging does not publish")
    staged=efis/"releases/9.9.9-test/esp32-efis-9.9.9-test.bin"
    check(staged.exists() and hashlib.sha256(staged.read_bytes()).hexdigest()==digest,"staged binary hash")

    r=client.post("/publish/9.9.9-test",follow_redirects=True); check(r.status_code==200,"publish action")
    manifest=json.loads((efis/"manifest.json").read_text())
    check(manifest["version"]=="9.9.9-test" and manifest["build"]==999,"manifest version/build")
    check(manifest["sha256"]==digest,"published SHA-256")
    check(manifest["image_url"]=="https://ota.test:8448/efis/releases/9.9.9-test/esp32-efis-9.9.9-test.bin","published image URL")
    r=client.post("/delete/9.9.9-test"); check(r.status_code==409,"published release cannot be deleted")

print("\nALL OTA ADMIN FUNCTIONAL TESTS PASSED")
