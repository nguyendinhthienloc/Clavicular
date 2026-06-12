# Project Proposal — BodyCheck

## Hackathon_Clavicular

## Executive Summary

BodyCheck is a lightweight medical guidance service designed to help users quickly describe and localize pain through an interactive 3D body model. After the user identifies the affected body region and provides symptom details, the system uses AI to generate clinician-style preliminary guidance, including possible conditions, recommended next steps, treatment considerations, and nearby healthcare facilities. Users can also interact with an AI chat interface to clarify symptoms and receive contextual follow-up guidance.

The system is intended to support triage-style decision-making, improve access to understandable health information, and streamline the process of connecting users with relevant clinical resources.

## Problem Statement

Non-specialist users, triage personnel, and healthcare support teams often need rapid, evidence-informed guidance from incomplete or unstructured symptom descriptions. Manually interpreting symptoms can be slow, inconsistent, and dependent on the experience of the operator. In addition, identifying relevant medical literature, care recommendations, and nearby clinical resources requires additional time and effort.

Current workflows often lack a simple, integratable service that can transform free-text symptom input and localized pain information into concise, uncertainty-aware clinical guidance suitable for downstream applications such as telehealth platforms, patient intake tools, or consumer health interfaces.

## Target Users

BodyCheck is designed for the following user groups:

* Clinical triage operators and telehealth nurses who need fast, consistent preliminary guidance.
* Primary-care clinicians seeking a concise opinion summary or source list before consultation.
* Health-conscious consumers who need immediate, understandable next-step advice and nearby care options.

## Proposed Solution

BodyCheck will be implemented as a two-tier service architecture:

1. **API Gateway — `backend`**

   The Node.js and Express backend will expose validated endpoints for diagnosis assistance, evidence source retrieval, clinic lookup, chat interactions, and media-related features.

2. **AI Microservice — `ai_dev`**

   The Python and FastAPI AI service will coordinate AI provider clients, normalize responses, manage request validation, maintain short-lived session history, and enforce clinician-style formatting and safety constraints.

Together, these services will provide a structured, extensible, and integration-ready system for AI-assisted medical guidance.

## Benefits of Using AI

AI provides several advantages for this use case:

* It can interpret brief, natural-language symptom descriptions and extract key clinical features.
* It can generate concise, uncertainty-qualified clinical impressions in triage-style language.
* It can help aggregate, summarize, and rank relevant evidence sources.
* It can support localized clinic recommendations based on user context.
* It can produce auxiliary outputs such as text-to-speech and annotated images to improve accessibility and frontend experience.
* It reduces the manual burden of preparing explanatory health content while maintaining consistent response formatting.

Importantly, BodyCheck is not intended to replace professional medical diagnosis. Its purpose is to provide preliminary guidance, support triage workflows, and help users determine appropriate next steps.

## Technical Overview and Architecture

### Core Components

The system consists of the following main components:

* **`backend` — Node.js + Express**

  Handles public API routes, request validation, middleware, CORS configuration, error handling, and communication with AI-related services.

* **`ai_dev` — Python + FastAPI**

  Coordinates AI model calls, provider integrations, request validation models, session history, and demo-facing AI workflows.

* **Provider Clients**

  Modular adapters are used to connect with external services, including OpenAI, Google GenAI, OpenRouter, ElevenLabs for text-to-speech, FAL or Gemini for image generation, and EXA for source search.

* **Frontend Artifacts**

  The project includes a simple demo HTML interface, a Flutter mobile client, and a `mock-ui` environment for integration testing.

### Data Flow

The primary request flow is:

```text
Client request
    -> backend route
    -> validation middleware
    -> ai_dev or AIService
    -> external provider APIs
    -> normalized ServiceResponse
    -> client
```

This structure separates public API handling from AI orchestration, making the system easier to maintain, test, and extend.

## Operational Considerations

The application will use environment variables for provider credentials, service URLs, and runtime configuration. Chat context will be stored in short-lived in-memory sessions during development, with optional persistent storage for production use.

Basic validation and rate-limiting middleware are included. For production deployment, additional hardening is required, including authentication, observability, quota enforcement, and secure secrets management.

## Deployment and Operations

For local development, the Node.js backend can be started with:

```bash
npm run dev
```

The Python AI service can be launched using Uvicorn.

For production, both services should be containerized and deployed using a minimal orchestration layer such as Docker Compose or Kubernetes. Secrets should be injected through environment variables or a secure vault mechanism rather than stored in source control.

Monitoring should include structured logging, request tracing, provider API latency tracking, error-rate monitoring, and alerting for failed or degraded external service calls.

## Safety, Privacy, and Compliance

Because BodyCheck handles health-related information, safety and privacy must be treated as core system requirements.

The system should:

* Avoid definitive diagnostic claims.
* Clearly communicate uncertainty in all medical guidance.
* Include explicit safety disclaimers and emergency-care escalation instructions where appropriate.
* Avoid logging protected health information in plaintext.
* Enforce TLS for internal and external traffic.
* Store API keys and secrets outside the codebase.
* Apply role-based access controls and API keys for partner integrations.
* Implement rate limits and abuse-detection mechanisms.

Before any clinical or public-facing deployment, legal and clinical review is strongly recommended.

## Security Considerations

Security controls should include:

* Environment-based or vault-based secret management.
* TLS enforcement for all service communication.
* Input validation at the API boundary.
* Authentication for production endpoints.
* Role-based access control for partner or administrative features.
* Rate limiting and abuse detection.
* Careful handling of user-submitted health information.
* Logging policies that prevent exposure of sensitive user data.

## Next Steps

The recommended next steps are:

1. Finalize a concise `README` with environment variable examples and startup instructions.
2. Add automated smoke tests for the following endpoints:

   * `/api/diagnose`
   * `/api/sources`
   * `/api/clinics`
   * `/api/chat`
3. Create Dockerfiles for both services.
4. Add a `docker-compose` manifest for local end-to-end testing.
5. Conduct a brief clinical-language and data-handling risk review before any user-facing release.

## Contact

For questions about the architecture or to request follow-up implementation work, please indicate which item should be prioritized next, such as smoke tests, documentation, containerization, or production hardening.
