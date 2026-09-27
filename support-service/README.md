# MicroSky Horizon Support Service

Dockerized support/RAG service for **MicroSky Horizon**.

## Principle

The service may learn *what customers ask*, but it does **not autonomously turn model output into product truth**. Customer interactions create candidate Q&A records. A human reviewer checks the answer against versioned product documents before promoting it into the validated Q&A knowledge base.

This prevents a hallucination, misunderstanding or malicious customer message from becoming future support guidance.

## Data flow

```
Product docs -> ingestion -> document store
                         -> retrieval
Customer -> chat/API -> answer + cited document paths -> interaction log
                                           |
                                           v
                                    candidate Q&A
                                           |
                                     human review
                                           |
                                           v
                                    validated Q&A
                                           |
                                    future answers
```

## Current MVP

- FastAPI support API on loopback port 8093
- PostgreSQL 17 persistent store
- version/revision-aware document ingestion
- lexical document retrieval baseline
- interaction history and feedback
- repeated-question aggregation
- candidate Q&A queue
- explicit admin approval into validated Q&A
- conservative fallback when no validated answer exists
- read-only/non-root application container

Generated LLM answers are deliberately not enabled in v0.1. The next phase adds a provider adapter and grounded-answer prompt after the validation workflow and test corpus are in place.

## Bring-up

```bash
cd support-service
cp .env.example .env
# set private DATABASE_URL, POSTGRES_PASSWORD and ADMIN_TOKEN
sudo docker compose config --quiet
sudo docker compose build support
sudo docker compose up -d
curl -fsS http://127.0.0.1:8093/healthz
```

Never commit `.env`, API keys, customer conversations or database dumps.

## Product-document ingestion

The production ingestion job should read approved repository documentation at a specific Git commit, split it into useful sections, and submit each section with path + revision. Do not ingest arbitrary customer text as documentation.

Authoritative sources initially include README, BOM and relevant `docs/` product/user/support documents. Internal secrets, signing material, private operational credentials and unrelated development logs must be excluded.

## Learning/validation model

1. Store each question, answer, source paths, confidence and optional feedback.
2. Normalize repeated questions into a candidate.
3. Rank candidates by frequency, negative feedback and lack of an approved answer.
4. Reviewer sees question, draft, source passages and document revisions.
5. Reviewer edits/approves/rejects.
6. Only approved content enters `validated_qa`.
7. Revalidate an answer when its supporting product documentation materially changes.

Future versions should add semantic clustering/embeddings, source-line citations, answer-version history, rejection reasons, PII minimization/retention, abuse controls, authentication/RBAC and audit records.

## Safety boundary

Horizon is a supplementary/non-primary flight instrument. Support answers concerning installation, operation, limitations, pressure/static systems, electrical interfaces, firmware or flight use must be grounded in current approved documentation and clearly distinguish development concepts from validated instructions.

The chatbot must never silently elevate an old design note, simulation result or customer statement into an approved operating instruction.
