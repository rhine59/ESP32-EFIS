import hashlib, json, os, re, shutil, tempfile
from pathlib import Path
from flask import Flask, abort, flash, redirect, render_template_string, request, url_for

ROOT=Path(os.environ.get('OTA_PUBLIC_ROOT','/data')); EFIS=ROOT/'efis'; RELEASES=EFIS/'releases'; MANIFEST=EFIS/'manifest.json'; META=EFIS/'release-metadata'
BASE_URL=os.environ.get('OTA_PUBLIC_BASE_URL','https://CHANGE-ME.example').rstrip('/'); PRODUCT='ESP32-EFIS'; HARDWARE='s3-n16r2-v1'; IDF='5.4.4'
VERSION_RE=re.compile(r'^[0-9A-Za-z][0-9A-Za-z._-]{0,63}$')
app=Flask(__name__); app.secret_key=os.environ.get('ADMIN_SESSION_SECRET','change-this-before-deployment')
PAGE='''<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ESP32 EFIS OTA Admin</title>
<style>
:root{color-scheme:dark;--bg:#0b1017;--panel:#141c27;--panel2:#192433;--line:#2a394c;--text:#eef4fb;--muted:#9fb0c3;--blue:#54a8ff;--green:#57d38c;--amber:#ffc766;--red:#ff6b73}
*{box-sizing:border-box}body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;margin:0;background:var(--bg);color:var(--text)}
.wrap{max-width:1180px;margin:auto;padding:28px 22px 60px}.hero{display:flex;justify-content:space-between;gap:20px;align-items:center;margin-bottom:22px}.eyebrow{color:var(--blue);font-size:.8rem;font-weight:800;letter-spacing:.13em;text-transform:uppercase}h1{font-size:2rem;margin:.25rem 0 .4rem}.subtitle{color:var(--muted);margin:0;max-width:720px;line-height:1.5}.health{white-space:nowrap;background:#10291d;color:#8ce9ae;border:1px solid #245d3d;border-radius:999px;padding:8px 12px;font-weight:700}
.grid{display:grid;grid-template-columns:1.35fr .65fr;gap:18px}.card{background:var(--panel);border:1px solid var(--line);border-radius:16px;padding:20px;box-shadow:0 12px 35px #0004}.card h2{margin:0 0 5px;font-size:1.1rem}.hint{color:var(--muted);font-size:.9rem;margin:0 0 18px}
table{width:100%;border-collapse:collapse}th{color:var(--muted);font-size:.75rem;text-transform:uppercase;letter-spacing:.06em}th,td{padding:12px 9px;border-bottom:1px solid var(--line);text-align:left}td code{font-size:.78rem;color:#c9d8e8}.empty{text-align:center;color:var(--muted);padding:28px}
.badge{display:inline-block;border-radius:999px;padding:5px 9px;font-size:.72rem;font-weight:800}.published{background:#123323;color:#78e8a6}.staged{background:#392d13;color:#ffd277}
label{display:block;color:#c7d3df;font-size:.86rem;font-weight:650;margin:13px 0 5px}.row{display:grid;grid-template-columns:1fr 1fr;gap:12px}input,textarea{width:100%;border:1px solid #35475d;background:#0d141e;color:var(--text);border-radius:9px;padding:10px 11px;font:inherit}input:focus,textarea:focus{outline:2px solid #2b78c5;border-color:transparent}input[type=file]{padding:8px}
button{border:0;border-radius:9px;padding:9px 12px;font:inherit;font-weight:750;cursor:pointer;background:#287fd4;color:white}button:hover{filter:brightness(1.08)}button.danger{background:#48242a;color:#ffadb2}button.secondary{background:#253447;color:#cbd8e6}button:disabled{opacity:.5;cursor:default}.actions form{display:inline}.actions button{font-size:.8rem;padding:7px 9px}
.flash{border:1px solid #35516f;background:#15263a;border-radius:10px;padding:11px 13px;margin:0 0 18px}.flow{display:flex;align-items:center;gap:7px;color:var(--muted);font-size:.82rem;margin-top:14px;flex-wrap:wrap}.flow b{color:var(--text);background:var(--panel2);padding:6px 9px;border-radius:7px}.manifest{margin-top:18px}.manifest-grid{display:grid;grid-template-columns:auto 1fr;gap:7px 12px;font-size:.86rem}.manifest-grid dt{color:var(--muted)}.manifest-grid dd{margin:0;word-break:break-all}.warning{color:var(--amber)}.footer{color:#718399;font-size:.78rem;margin-top:18px}
@media(max-width:800px){.grid{grid-template-columns:1fr}.hero{align-items:flex-start;flex-direction:column}.row{grid-template-columns:1fr}.tablewrap{overflow-x:auto}}
</style>
</head>
<body><div class="wrap">
<div class="hero"><div><div class="eyebrow">ESP32 EFIS · Maintenance</div><h1>Firmware Administration</h1><p class="subtitle">Stage, review and publish firmware for the supplementary ESP32 EFIS. Uploading never makes firmware available to instruments until you explicitly publish it.</p></div><div class="health">● OTA server online</div></div>
{% for m in get_flashed_messages() %}<div class="flash">{{m}}</div>{% endfor %}
<div class="grid">
<section class="card"><h2>Firmware releases</h2><p class="hint">Published is the version currently advertised to EFIS units. Other versions remain staged or archived.</p><div class="tablewrap"><table><tr><th>Version</th><th>Build</th><th>Size</th><th>SHA-256</th><th>Status</th><th>Actions</th></tr>
{% for r in releases %}<tr><td><b>{{r.version}}</b></td><td>{{r.build}}</td><td>{{"%.1f"|format(r.size/1024)}} KB</td><td><code title="{{r.sha}}">{{r.sha[:12]}}…</code></td><td>{% if r.version==current %}<span class="badge published">PUBLISHED</span>{% else %}<span class="badge staged">STAGED</span>{% endif %}</td><td class="actions">{% if r.version!=current %}<form method="post" action="{{url_for('publish',version=r.version)}}" onsubmit="return confirm('Publish {{r.version}} to EFIS units?')"><button>Publish</button></form> <form method="post" action="{{url_for('delete',version=r.version)}}" onsubmit="return confirm('Permanently delete hosted release {{r.version}}?')"><button class="danger">Delete</button></form>{% else %}<button class="secondary" disabled>Current</button>{% endif %}</td></tr>{% else %}<tr><td colspan="6" class="empty">No firmware releases have been staged yet.</td></tr>{% endfor %}
</table></div><div class="flow"><b>1 · Upload</b> → <b>2 · Staged</b> → <b>3 · Review</b> → <b>4 · Publish</b> → EFIS</div></section>
<section class="card"><h2>Stage new firmware</h2><p class="hint">Choose an approved ESP32 application binary. It remains private until Publish is selected.</p>
<form method="post" action="{{url_for('upload')}}" enctype="multipart/form-data"><div class="row"><div><label>Version</label><input name="version" required placeholder="0.4.2"></div><div><label>Build number</label><input name="build" type="number" min="0" required placeholder="52"></div></div><label>Minimum allowed version</label><input name="minimum" value="0.0.0" required><label>Release notes</label><textarea name="notes" rows="4" placeholder="What changed in this release?"></textarea><label>Firmware binary (.bin)</label><input type="file" name="firmware" accept=".bin,application/octet-stream" required><p class="hint warning">Uploading stages the file only. Instruments cannot see it until you explicitly publish.</p><button>Upload to staging</button></form></section>
</div>
<section class="card manifest"><h2>Currently published manifest</h2>{% if manifest %}<dl class="manifest-grid"><dt>Product</dt><dd>{{manifest.get('product','—')}}</dd><dt>Version</dt><dd><b>{{manifest.get('version','—')}}</b> · build {{manifest.get('build','—')}}</dd><dt>Hardware</dt><dd>{{manifest.get('hardware_profile','—')}}</dd><dt>ESP-IDF</dt><dd>{{manifest.get('idf','—')}}</dd><dt>Image</dt><dd><code>{{manifest.get('image_url','—')}}</code></dd><dt>SHA-256</dt><dd><code>{{manifest.get('sha256','—')}}</code></dd><dt>Minimum version</dt><dd>{{manifest.get('minimum_allowed_version','—')}}</dd><dt>Release notes</dt><dd>{{manifest.get('release_notes','—')}}</dd></dl>{% else %}<p class="hint">No published manifest is available.</p>{% endif %}</section>
<div class="footer">Private administration interface · Publishing changes the public OTA manifest; activation on an EFIS remains a separate local action.</div>
</div></body></html>'''
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
