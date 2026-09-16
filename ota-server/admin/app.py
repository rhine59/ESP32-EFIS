import hashlib
import json
import os
import re
import shutil
import tempfile
from pathlib import Path
from flask import Flask, abort, flash, redirect, render_template_string, request, url_for
from werkzeug.utils import secure_filename

ROOT = Path(os.environ.get("OTA_PUBLIC_ROOT", "/data"))
EFIS = ROOT / "efis"
RELEASES = EFIS / "releases"
MANIFEST = EFIS / "manifest.json"
BASE_URL = os.environ.get("OTA_PUBLIC_BASE_URL", "https://CHANGE-ME.example").rstrip("/")
PRODUCT = "ESP32-EFIS"
HARDWARE = "s3-n16r2-v1"
IDF = "5.4.4"
VERSION_RE = re.compile(r"^[0-9A-Za-z][0-9A-Za-z._-]{0,63}$")
app = Flask(__name__)
app.secret_key = os.environ.get("ADMIN_SESSION_SECRET", "change-this-before-deployment")

PAGE = '''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>ESP32 EFIS OTA Admin</title><style>body{font-family:system-ui;margin:2rem auto;max-width:980px;padding:0 1rem;background:#111;color:#eee}a{color:#8cc8ff}table{width:100%;border-collapse:collapse}th,td{padding:.65rem;border-bottom:1px solid #444;text-align:left}input,button,textarea{font:inherit;padding:.55rem;margin:.2rem}fieldset{border:1px solid #555;margin:1.2rem 0} .current{color:#80e080;font-weight:700}.warn{color:#ffcf70}.flash{padding:.7rem;background:#333}</style></head><body><h1>ESP32 EFIS OTA Admin</h1><p class="warn">Maintenance interface. Keep this endpoint private/authenticated. Public EFIS devices use only the read-only download service.</p>{% for m in get_flashed_messages() %}<p class="flash">{{m}}</p>{% endfor %}<h2>Published releases</h2><table><tr><th>Version</th><th>Size</th><th>SHA-256</th><th>Status</th><th>Actions</th></tr>{% for r in releases %}<tr><td>{{r.version}}</td><td>{{r.size}}</td><td><code>{{r.sha[:16]}}…</code></td><td>{% if r.version == current %}<span class="current">CURRENT</span>{% endif %}</td><td><form method="post" action="{{url_for('activate',version=r.version)}}" style="display:inline"><button {% if r.version == current %}disabled{% endif %}>Make current</button></form><form method="post" action="{{url_for('delete',version=r.version)}}" style="display:inline" onsubmit="return confirm('Delete {{r.version}}?')"><button {% if r.version == current %}disabled{% endif %}>Delete</button></form></td></tr>{% endfor %}</table><fieldset><legend>Upload approved firmware</legend><form method="post" action="{{url_for('upload')}}" enctype="multipart/form-data"><label>Version <input name="version" required placeholder="0.4.1"></label><label>Build <input name="build" type="number" min="0" required></label><br><label>Minimum allowed version <input name="minimum" value="0.0.0"></label><br><label>Release notes<br><textarea name="notes" rows="3" cols="60"></textarea></label><br><input type="file" name="firmware" accept=".bin,application/octet-stream" required><button>Upload and publish</button></form></fieldset><p>Manifest: <code>{{manifest}}</code></p></body></html>'''

def load_manifest():
    try: return json.loads(MANIFEST.read_text())
    except Exception: return {}

def sha256(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024), b''): h.update(chunk)
    return h.hexdigest()

def inventory():
    current=load_manifest().get('version','')
    rows=[]
    if RELEASES.exists():
        for d in sorted((p for p in RELEASES.iterdir() if p.is_dir()), reverse=True):
            bins=list(d.glob('*.bin'))
            if bins:
                p=bins[0]; rows.append({'version':d.name,'size':p.stat().st_size,'sha':sha256(p)})
    return rows,current

def write_manifest(version, build, minimum, notes, image):
    data={'product':PRODUCT,'version':version,'build':int(build),'hardware_profile':HARDWARE,'idf':IDF,'image_url':f'{BASE_URL}/efis/releases/{version}/{image.name}','sha256':sha256(image),'minimum_allowed_version':minimum,'release_notes':notes}
    EFIS.mkdir(parents=True,exist_ok=True)
    fd,tmp=tempfile.mkstemp(dir=EFIS,prefix='.manifest.',text=True)
    with os.fdopen(fd,'w') as f: json.dump(data,f,indent=2); f.write('\n')
    os.replace(tmp,MANIFEST)

@app.get('/')
def index():
    releases,current=inventory(); return render_template_string(PAGE,releases=releases,current=current,manifest=load_manifest())

@app.post('/upload')
def upload():
    version=request.form.get('version','').strip(); build=request.form.get('build','').strip(); minimum=request.form.get('minimum','0.0.0').strip(); notes=request.form.get('notes','').strip(); f=request.files.get('firmware')
    if not VERSION_RE.fullmatch(version) or not build.isdigit() or not VERSION_RE.fullmatch(minimum): abort(400)
    if not f or not f.filename.lower().endswith('.bin'): abort(400)
    target=RELEASES/version
    if target.exists(): abort(409, 'Version already exists')
    target.mkdir(parents=True)
    image=target/f'esp32-efis-{version}.bin'
    try:
        f.save(image)
        if image.stat().st_size < 1024: raise ValueError('Firmware image is implausibly small')
        write_manifest(version,build,minimum,notes or f'Approved ESP32 EFIS release {version}',image)
    except Exception:
        shutil.rmtree(target,ignore_errors=True); raise
    flash(f'Uploaded {version}; SHA-256 {sha256(image)}; release is now current.')
    return redirect(url_for('index'))

@app.post('/activate/<version>')
def activate(version):
    if not VERSION_RE.fullmatch(version): abort(400)
    bins=list((RELEASES/version).glob('*.bin'))
    if len(bins)!=1: abort(404)
    old=load_manifest(); write_manifest(version,old.get('build',0),old.get('minimum_allowed_version','0.0.0'),f'Reactivated ESP32 EFIS release {version}',bins[0])
    flash(f'{version} is now the current advertised release.')
    return redirect(url_for('index'))

@app.post('/delete/<version>')
def delete(version):
    if not VERSION_RE.fullmatch(version): abort(400)
    if load_manifest().get('version')==version: abort(409,'Cannot delete current release')
    target=RELEASES/version
    if not target.is_dir(): abort(404)
    shutil.rmtree(target); flash(f'Deleted hosted release {version}.')
    return redirect(url_for('index'))

@app.get('/healthz')
def health(): return {'status':'ok'}
