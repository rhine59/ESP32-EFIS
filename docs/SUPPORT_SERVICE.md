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
