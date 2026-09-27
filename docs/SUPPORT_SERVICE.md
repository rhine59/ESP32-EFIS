# MicroSky Horizon customer support chatbot

**Status:** ARCHITECTURE ADOPTED / MVP STAGED / RUNTIME VALIDATION PENDING  
**Date:** 27 September 2026

## Objective

Provide a Docker-hosted MicroSky Horizon customer support service with access to approved product documentation and a controlled learning loop that builds a useful, **validated Q&A knowledge base** from real customer interactions.

## Core design decision

Customer conversations are learning input, **not authority**. The system learns question frequency, wording, gaps and feedback automatically. New answers remain candidates until a reviewer validates them against current product documentation.

This is deliberately a human-in-the-loop knowledge system rather than an autonomously self-training chatbot.

## Architecture

- `support`: FastAPI chat/retrieval/feedback/review API.
- `db`: PostgreSQL persistent document, interaction, candidate and validated-Q&A store.
- Product-document ingestion tied to Git revision.
- Retrieval layer; lexical MVP, semantic/vector retrieval planned.
- Future LLM provider adapter receives only retrieved approved context plus validated Q&A.
- Future customer web widget/mobile integration calls versioned support API.
- Admin/reviewer UI remains private and authenticated.

The service is separate from OTA, licence signer and account services. It must not receive licence private keys, payment-card data, OTA signing secrets or aircraft/device credentials.

## Knowledge lifecycle

`approved docs -> retrieve -> answer -> interaction -> candidate -> review -> validated Q&A -> answer`

When source documentation changes, affected validated answers should be marked for revalidation rather than assumed current.

## Data/privacy

Collect the minimum conversation/account metadata required for support. Define retention/deletion/export policy before public launch. Redact secrets and unnecessary personal data. Customer text must never be copied into the authoritative product-document corpus.

## Production gates

Before public exposure: authenticated admin/RBAC, CSRF where relevant, rate limiting/abuse controls, TLS/reverse-proxy policy, PII retention controls, backup/restore test, migrations, audit trail, semantic retrieval evaluation, grounded LLM adapter, prompt-injection tests, source citations, stale-document invalidation, support escalation, monitoring and a reviewed test set of expected answers.

No runtime/build-success claim is made until the Docker harness is run on the Synology.


## Grounded LLM answering — 27 September 2026

**IMPLEMENTED IN MVP / RUNTIME VALIDATION PENDING.** The support API now has a provider-neutral OpenAI-compatible chat-completions adapter. Natural-language questions first retrieve approved product-document evidence. The LLM is instructed to answer only from that evidence, cite source numbers, distinguish provisional development material from validated instructions, avoid unsupported safety/certification/capability claims and explicitly escalate when evidence is insufficient.

LLM output is never promoted directly to authoritative knowledge. It is stored as an interaction and candidate Q&A and must pass the existing human validation workflow before entering `validated_qa`. Exact validated Q&A takes precedence over generation. Provider failure falls back conservatively to retrieved source material.

Provider URL/key/model are runtime secrets/configuration, not repository content. Production still requires semantic retrieval evaluation, source-level citation mapping, privacy/retention review, token/cost limits, authentication/rate limiting and prompt-injection/red-team testing.


## Semantic/vector retrieval — 27 September 2026

**IMPLEMENTED IN REPOSITORY / RUNTIME EVALUATION PENDING.** PostgreSQL is now based on the pgvector PG17 image. Approved document sections receive embeddings through a configurable OpenAI-compatible embedding endpoint. Natural-language questions are embedded and ranked against document vectors by cosine distance before grounded LLM generation. Lexical retrieval remains the fail-safe fallback if embeddings are not configured or the provider fails.

Embedding model and dimensionality are deployment configuration and must be frozen per index generation. Model/dimension changes require controlled re-embedding/migration. Retrieval quality still requires a representative Horizon support-question test set before public launch.


## Answer status and customer resolution — 27 September 2026

Every response must make its knowledge status visible to the customer. Supported states are **VALIDATED**, **GENERATED — NOT YET VALIDATED**, **RETRIEVED — NOT YET VALIDATED**, **INVALIDATED**, and **NO VALIDATED ANSWER**. Invalidated historical answers may be retrieved when relevant, but they must be conspicuously labelled as superseded/not-current guidance, carry the invalidation reason where available, and must never be presented as an approved answer.

After each answer the interaction asks **“Did this answer resolve your question?”**. The yes/no result is stored separately from optional positive/negative feedback. Customer resolution is evidence about answer usefulness, not technical validation: even many successful customer confirmations cannot promote an answer into the validated knowledge base without the formal reviewer process. Conversely, unresolved interactions should increase review priority and help identify missing documentation, weak retrieval and inadequate answers.

The future reviewer dashboard should show answer status, source/revision, number of occurrences, resolution rate, feedback, invalidation history and candidate/validated lineage. It should support explicit invalidate/supersede operations without deleting the historical answer.
