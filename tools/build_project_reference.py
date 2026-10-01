#!/usr/bin/env python3
from pathlib import Path
import re, html, json
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,PageBreak,Preformatted,KeepTogether
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"dist"/"MicroSky-Horizon-Project-Reference.pdf"
OUT.parent.mkdir(exist_ok=True)

def wanted(p):
    s=p.as_posix()
    if any(x in s for x in ["/build-","/.git/","CMakeFiles","__pycache__"]): return False
    if p.suffix.lower()==".md":
        return s=="README.md" or s=="BOM.md" or s.startswith("docs/") or s.endswith("/README.md") or s.endswith("/DEPLOYMENT.md") or s.endswith("/BUILD-AND-DEPLOY.md") or s.endswith("CARRIER_PCB_SCHEMATIC.md")
    return s in {"protocol/aef-can.yaml","protocol/golden-vectors.txt","ota-server/release-set.example.json"}

files=sorted([p for p in ROOT.rglob("*") if p.is_file() and wanted(p)],key=lambda p:p.as_posix().lower())
styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name="DocTitle",parent=styles["Heading1"],fontSize=18,leading=22,spaceAfter=10))
styles.add(ParagraphStyle(name="H1x",parent=styles["Heading1"],fontSize=15,leading=19,spaceBefore=10,spaceAfter=6))
styles.add(ParagraphStyle(name="H2x",parent=styles["Heading2"],fontSize=12,leading=15,spaceBefore=8,spaceAfter=4))
styles.add(ParagraphStyle(name="BodyX",parent=styles["BodyText"],fontSize=8.5,leading=11,spaceAfter=4))
styles.add(ParagraphStyle(name="Path",parent=styles["BodyText"],fontSize=7.5,leading=9,textColor="#555555",spaceAfter=8))
styles.add(ParagraphStyle(name="Cover",parent=styles["Title"],fontSize=26,leading=31,alignment=TA_CENTER,spaceAfter=14))
styles.add(ParagraphStyle(name="Small",parent=styles["BodyText"],fontSize=7.5,leading=9))
code=ParagraphStyle("CodeX",fontName="Courier",fontSize=6.5,leading=8,leftIndent=6,rightIndent=4,spaceAfter=5,backColor="#f4f4f4")

def esc(s): return html.escape(s).replace("  "," &nbsp;")
def inline(s):
    s=html.escape(s)
    s=re.sub(r'`([^`]+)`',r'<font name="Courier">\1</font>',s)
    s=re.sub(r'\*\*([^*]+)\*\*',r'<b>\1</b>',s)
    s=re.sub(r'(?<!\*)\*([^*]+)\*',r'<i>\1</i>',s)
    return s

story=[]
story += [Spacer(1,35*mm),Paragraph("MicroSky Horizon",styles["Cover"]),Paragraph("ESP32-EFIS Project Reference",styles["Cover"]),
          Spacer(1,8*mm),Paragraph("Indexed compilation of the current repository documentation",styles["Normal"]),
          Spacer(1,4*mm),Paragraph(f"{len(files)} source documents",styles["Normal"]),PageBreak()]
story.append(Paragraph("Contents",styles["DocTitle"]))
toc=TableOfContents();toc.levelStyles=[ParagraphStyle(name="TOC1",fontSize=9,leading=12,leftIndent=0,firstLineIndent=0),ParagraphStyle(name="TOC2",fontSize=8,leading=10,leftIndent=12,firstLineIndent=0)]
story += [toc,PageBreak(),Paragraph("Document index",styles["DocTitle"])]
for p in files: story.append(Paragraph(inline(p.as_posix()),styles["BodyX"]))
story.append(PageBreak())

for idx,p in enumerate(files):
    rel=p.as_posix(); text=p.read_text(errors="replace")
    story.append(Paragraph(inline(rel),styles["DocTitle"]))
    story.append(Paragraph("Repository source: "+inline(rel),styles["Path"]))
    in_code=False; buf=[]
    def flush_code(lines):
        if lines:
            story.append(Preformatted("\n".join(lines),code))
        return []
    for raw in text.splitlines():
        line=raw.rstrip()
        if line.startswith("```"):
            if in_code: buf=flush_code(buf)
            in_code=not in_code; continue
        if in_code: buf.append(line); continue
        if not line.strip(): story.append(Spacer(1,2)); continue
        m=re.match(r'^(#{1,6})\s+(.*)$',line)
        if m:
            lev=len(m.group(1)); title=m.group(2)
            st=styles["H1x"] if lev<=2 else styles["H2x"]
            story.append(Paragraph(inline(title),st)); continue
        if line.startswith("|") and line.endswith("|"):
            story.append(Paragraph(inline(line),styles["Small"])); continue
        if re.match(r'^\s*[-*+]\s+',line):
            story.append(Paragraph("• "+inline(re.sub(r'^\s*[-*+]\s+','',line)),styles["BodyX"]));continue
        if re.match(r'^\s*\d+[.)]\s+',line):
            story.append(Paragraph(inline(line),styles["BodyX"]));continue
        story.append(Paragraph(inline(line),styles["BodyX"]))
    buf=flush_code(buf)
    if idx<len(files)-1: story.append(PageBreak())

class IndexedDoc(SimpleDocTemplate):
    def afterFlowable(self,flowable):
        if isinstance(flowable,Paragraph):
            txt=flowable.getPlainText()
            if flowable.style.name=="DocTitle":
                key="doc_"+str(abs(hash(txt)))
                self.canv.bookmarkPage(key); self.canv.addOutlineEntry(txt,key,level=0,closed=False)
                self.notify("TOCEntry",(0,txt,self.page,key))
            elif flowable.style.name=="H1x":
                key="h_"+str(abs(hash(txt+str(self.page))))
                self.canv.bookmarkPage(key); self.canv.addOutlineEntry(txt,key,level=1,closed=True)
                self.notify("TOCEntry",(1,txt,self.page,key))

def footer(canvas,doc):
    canvas.saveState();canvas.setFont("Helvetica",7)
    canvas.drawString(18*mm,10*mm,"MicroSky Horizon - Project Reference")
    canvas.drawRightString(192*mm,10*mm,f"Page {doc.page}")
    canvas.restoreState()

doc=IndexedDoc(str(OUT),pagesize=A4,rightMargin=16*mm,leftMargin=16*mm,topMargin=15*mm,bottomMargin=16*mm,title="MicroSky Horizon Project Reference",author="ESP32-EFIS project")
doc.multiBuild(story,onFirstPage=footer,onLaterPages=footer)
print(OUT)
