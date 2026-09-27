import hashlib, os, re
from datetime import datetime, timezone
from typing import Optional
import psycopg
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

DB=os.environ["DATABASE_URL"]
ADMIN=os.getenv("ADMIN_TOKEN","")
PRODUCT=os.getenv("PRODUCT_NAME","MicroSky Horizon")
app=FastAPI(title=f"{PRODUCT} Support",version="0.1.0")

SCHEMA="""
CREATE TABLE IF NOT EXISTS documents(
 id bigserial primary key, path text not null, revision text, content text not null,
 content_sha256 text not null unique, ingested_at timestamptz not null default now());
CREATE INDEX IF NOT EXISTS documents_path_idx ON documents(path);
CREATE TABLE IF NOT EXISTS interactions(
 id bigserial primary key, session_id text, question text not null, answer text not null,
 sources text[] not null default '{}', confidence real, user_feedback smallint,
 created_at timestamptz not null default now());
CREATE TABLE IF NOT EXISTS qa_candidates(
 id bigserial primary key, normalized_question text not null, draft_answer text not null,
 evidence_paths text[] not null default '{}', occurrences int not null default 1,
 status text not null default 'candidate',
 reviewer_note text, created_at timestamptz not null default now(),
 updated_at timestamptz not null default now());
CREATE UNIQUE INDEX IF NOT EXISTS qa_candidate_q_idx ON qa_candidates(normalized_question);
CREATE TABLE IF NOT EXISTS validated_qa(
 id bigserial primary key, question text not null, answer text not null,
 evidence_paths text[] not null default '{}', approved_by text not null,
 approved_at timestamptz not null default now(), active boolean not null default true);
"""

def conn():
    return psycopg.connect(DB)

@app.on_event("startup")
def startup():
    with conn() as c: c.execute(SCHEMA)

class Document(BaseModel):
    path:str
    revision:Optional[str]=None
    content:str=Field(min_length=1)

class Ask(BaseModel):
    question:str=Field(min_length=2,max_length=2000)
    session_id:Optional[str]=None

class Feedback(BaseModel):
    interaction_id:int
    score:int=Field(ge=-1,le=1)

class Approve(BaseModel):
    candidate_id:int
    answer:Optional[str]=None
    approved_by:str="admin"
    note:Optional[str]=None

def require_admin(token):
    if not ADMIN or token != ADMIN: raise HTTPException(403,"admin authorization required")

def norm(q):
    return re.sub(r"\s+"," ",re.sub(r"[^a-z0-9 ]"," ",q.lower())).strip()

def retrieve(c,q,limit=5):
    # Deliberately simple lexical baseline. Replace with embeddings after evaluation.
    terms=[x for x in norm(q).split() if len(x)>3][:8]
    if not terms: return []
    pattern="|".join(map(re.escape,terms))
    rows=c.execute("""SELECT path,revision,content FROM documents
      WHERE content ~* %s ORDER BY ingested_at DESC LIMIT %s""",(pattern,limit)).fetchall()
    return rows

@app.get("/healthz")
def health():
    with conn() as c: c.execute("SELECT 1")
    return {"ok":True,"product":PRODUCT}

@app.post("/internal/v1/documents")
def ingest(d:Document, authorization:Optional[str]=Header(None)):
    require_admin(authorization)
    sha=hashlib.sha256(d.content.encode()).hexdigest()
    with conn() as c:
        c.execute("""INSERT INTO documents(path,revision,content,content_sha256)
          VALUES(%s,%s,%s,%s) ON CONFLICT(content_sha256) DO NOTHING""",
          (d.path,d.revision,d.content,sha))
    return {"ok":True,"sha256":sha}

@app.post("/v1/ask")
def ask(a:Ask):
    qn=norm(a.question)
    with conn() as c:
        exact=c.execute("""SELECT question,answer,evidence_paths FROM validated_qa
          WHERE active AND lower(question)=lower(%s) ORDER BY approved_at DESC LIMIT 1""",
          (a.question.strip(),)).fetchone()
        if exact:
            answer=exact[1]; sources=exact[2]; confidence=1.0
        else:
            docs=retrieve(c,a.question)
            sources=[r[0] for r in docs]
            if docs:
                # Safe MVP: evidence is returned for a future LLM adapter; do not invent an answer.
                snippets="\n\n".join(f"[{p}] {txt[:900]}" for p,_,txt in docs)
                answer=("I found relevant product documentation, but this prototype has not yet "
                        "enabled generated answers. A support reviewer can validate this question.\n\n"
                        + snippets[:3000])
                confidence=0.35
            else:
                answer="I don't have validated product information to answer that yet."
                confidence=0.0
        iid=c.execute("""INSERT INTO interactions(session_id,question,answer,sources,confidence)
          VALUES(%s,%s,%s,%s,%s) RETURNING id""",
          (a.session_id,a.question,answer,sources,confidence)).fetchone()[0]
        c.execute("""INSERT INTO qa_candidates(normalized_question,draft_answer,evidence_paths)
          VALUES(%s,%s,%s) ON CONFLICT(normalized_question) DO UPDATE
          SET occurrences=qa_candidates.occurrences+1,updated_at=now()""",(qn,answer,sources))
    return {"interaction_id":iid,"answer":answer,"sources":sources,"confidence":confidence}

@app.post("/v1/feedback")
def feedback(f:Feedback):
    with conn() as c:
        n=c.execute("UPDATE interactions SET user_feedback=%s WHERE id=%s",(f.score,f.interaction_id)).rowcount
    if not n: raise HTTPException(404,"interaction not found")
    return {"ok":True}

@app.get("/internal/v1/candidates")
def candidates(authorization:Optional[str]=Header(None)):
    require_admin(authorization)
    with conn() as c:
        rows=c.execute("""SELECT id,normalized_question,draft_answer,evidence_paths,occurrences,status
          FROM qa_candidates WHERE status='candidate' ORDER BY occurrences DESC,updated_at DESC LIMIT 100""").fetchall()
    return [{"id":r[0],"question":r[1],"draft_answer":r[2],"evidence":r[3],"occurrences":r[4],"status":r[5]} for r in rows]

@app.post("/internal/v1/approve")
def approve(a:Approve, authorization:Optional[str]=Header(None)):
    require_admin(authorization)
    with conn() as c:
        r=c.execute("""SELECT normalized_question,draft_answer,evidence_paths FROM qa_candidates
          WHERE id=%s AND status='candidate'""",(a.candidate_id,)).fetchone()
        if not r: raise HTTPException(404,"candidate not found")
        answer=a.answer or r[1]
        c.execute("""INSERT INTO validated_qa(question,answer,evidence_paths,approved_by)
          VALUES(%s,%s,%s,%s)""",(r[0],answer,r[2],a.approved_by))
        c.execute("""UPDATE qa_candidates SET status='approved',reviewer_note=%s,updated_at=now()
          WHERE id=%s""",(a.note,a.candidate_id))
    return {"ok":True}
