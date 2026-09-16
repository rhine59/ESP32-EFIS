import hashlib, json, os, re, shutil, tempfile
from pathlib import Path
from flask import Flask, abort, flash, redirect, render_template_string, request, url_for

ROOT=Path(os.environ.get('OTA_PUBLIC_ROOT','/data')); EFIS=ROOT/'efis'; RELEASES=EFIS/'releases'; MANIFEST=EFIS/'manifest.json'; META=EFIS/'release-metadata'
BASE_URL=os.environ.get('OTA_PUBLIC_BASE_URL','https://CHANGE-ME.example').rstrip('/'); PRODUCT='ESP32-EFIS'; HARDWARE='s3-n16r2-v1'; IDF='5.4.4'
VERSION_RE=re.compile(r'^[0-9A-Za-z][0-9A-Za-z._-]{0,63}$')
app=Flask(__name__); app.secret_key=os.environ.get('ADMIN_SESSION_SECRET','change-this-before-deployment')
PAGE='''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>ESP32 EFIS OTA Admin</title><style>body{font-family:system-ui;margin:2rem auto;max-width:1050px;padding:0 1rem;background:#111;color:#eee}table{width:100%;border-collapse:collapse}th,td{padding:.65rem;border-bottom:1px solid #444;text-align:left}input,button,textarea{font:inherit;padding:.55rem;margin:.2rem}fieldset{border:1px solid #555;margin:1.2rem 0}.published{color:#80e080;font-weight:700}.staged{color:#ffcf70;font-weight:700}.flash{padding:.7rem;background:#333}</style></head><body><h1>ESP32 EFIS Firmware Repository</h1><p>Upload creates a <b>STAGED</b> release. Only an explicit <b>Publish</b> action changes the public manifest seen by EFIS units.</p>{% for m in get_flashed_messages() %}<p class="flash">{{m}}</p>{% endfor %}<table><tr><th>Version</th><th>Build</th><th>Size</th><th>SHA-256</th><th>Status</th><th>Actions</th></tr>{% for r in releases %}<tr><td>{{r.version}}</td><td>{{r.build}}</td><td>{{r.size}}</td><td><code>{{r.sha[:16]}}…</code></td><td>{% if r.version==current %}<span class="published">PUBLISHED</span>{% else %}<span class="staged">STAGED / ARCHIVED</span>{% endif %}</td><td>{% if r.version!=current %}<form method="post" action="{{url_for('publish',version=r.version)}}" style="display:inline" onsubmit="return confirm('Publish {{r.version}} to EFIS units?')"><button>Publish</button></form><form method="post" action="{{url_for('delete',version=r.version)}}" style="display:inline" onsubmit="return confirm('Delete {{r.version}}?')"><button>Delete</button></form>{% else %}<button disabled>Current</button>{% endif %}</td></tr>{% endfor %}</table><fieldset><legend>Stage approved firmware</legend><form method="post" action="{{url_for('upload')}}" enctype="multipart/form-data"><label>Version <input name="version" required placeholder="0.4.2"></label><label>Build <input name="build" type="number" min="0" required></label><br><label>Minimum allowed version <input name="minimum" value="0.0.0" required></label><br><label>Release notes<br><textarea name="notes" rows="3" cols="60"></textarea></label><br><input type="file" name="firmware" accept=".bin,application/octet-stream" required><button>Upload to staging</button></form></fieldset><p><b>Published manifest:</b> <code>{{manifest}}</code></p></body></html>'''

def load_json(p):
    try:return json.loads(p.read_text())
    except Exception:return {}
def sha256(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for c in iter(lambda:f.read(1024*1024),b''):h.update(c)
    return h.hexdigest()
def atomic_json(p,data):
    p.parent.mkdir(parents=True,exist_ok=True); fd,tmp=tempfile.mkstemp(dir=p.parent,prefix='.'+p.name+'.',text=True)
    with os.fdopen(fd,'w') as f:json.dump(data,f,indent=2);f.write('\n')
    os.replace(tmp,p)
def metadata(version):return load_json(META/f'{version}.json')
def inventory():
    current=load_json(MANIFEST).get('version',''); rows=[]
    if RELEASES.exists():
        for d in sorted((p for p in RELEASES.iterdir() if p.is_dir()),reverse=True):
            bins=list(d.glob('*.bin'))
            if bins:
                p=bins[0]; m=metadata(d.name); rows.append({'version':d.name,'build':m.get('build','?'),'size':p.stat().st_size,'sha':sha256(p)})
    return rows,current
def publish_manifest(version,image):
    m=metadata(version)
    if not m:abort(409,'Release metadata missing')
    atomic_json(MANIFEST,{'product':PRODUCT,'version':version,'build':int(m['build']),'hardware_profile':HARDWARE,'idf':IDF,'image_url':f'{BASE_URL}/efis/releases/{version}/{image.name}','sha256':sha256(image),'minimum_allowed_version':m['minimum_allowed_version'],'release_notes':m['release_notes']})

@app.get('/')
def index():
    releases,current=inventory();return render_template_string(PAGE,releases=releases,current=current,manifest=load_json(MANIFEST))
@app.post('/upload')
def upload():
    version=request.form.get('version','').strip();build=request.form.get('build','').strip();minimum=request.form.get('minimum','0.0.0').strip();notes=request.form.get('notes','').strip();f=request.files.get('firmware')
    if not VERSION_RE.fullmatch(version) or not build.isdigit() or not VERSION_RE.fullmatch(minimum):abort(400)
    if not f or not f.filename.lower().endswith('.bin'):abort(400)
    target=RELEASES/version
    if target.exists():abort(409,'Version already exists')
    target.mkdir(parents=True);image=target/f'esp32-efis-{version}.bin'
    try:
        f.save(image)
        if image.stat().st_size<1024:raise ValueError('Firmware image is implausibly small')
        atomic_json(META/f'{version}.json',{'version':version,'build':int(build),'minimum_allowed_version':minimum,'release_notes':notes or f'ESP32 EFIS release {version}','sha256':sha256(image)})
    except Exception:
        shutil.rmtree(target,ignore_errors=True);raise
    flash(f'Uploaded {version} to staging. It is NOT visible to EFIS units until Publish is selected.')
    return redirect(url_for('index'))
@app.post('/publish/<version>')
def publish(version):
    if not VERSION_RE.fullmatch(version):abort(400)
    bins=list((RELEASES/version).glob('*.bin'))
    if len(bins)!=1:abort(404)
    publish_manifest(version,bins[0]);flash(f'{version} is now PUBLISHED and advertised to EFIS units.');return redirect(url_for('index'))
@app.post('/delete/<version>')
def delete(version):
    if not VERSION_RE.fullmatch(version):abort(400)
    if load_json(MANIFEST).get('version')==version:abort(409,'Cannot delete published release')
    target=RELEASES/version
    if not target.is_dir():abort(404)
    shutil.rmtree(target);(META/f'{version}.json').unlink(missing_ok=True);flash(f'Deleted hosted release {version}.');return redirect(url_for('index'))
@app.get('/healthz')
def health():return {'status':'ok'}
