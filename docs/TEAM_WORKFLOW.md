# Team workflow

## Roles (5-7 students)
1. Flutter UI/UX and design system (`app/lib/core/theme`, `core/widgets`)
2. Flutter features and navigation (`app/lib/features/*`, `app/lib/app/router.dart`)
3. Backend and auth (`backend/.../auth`, `user`, `security`)
4. Database, Flyway migrations, ERD (`backend/src/main/resources/db`, `backend/docs`)
5. AI and retrieval (`backend/.../ai`, `itinerary`)
6. Maps, booking and payments (`app/lib/features/maps`, `backend/.../booking`, `payment`)
7. QA, DevOps, docs (`backend/src/test`, `backend/scripts`, `.github`, `docs`)

## Git
`main` (deployable) <- `develop` <- `feature/<area>-<topic>`. Pull requests need CI green and one review. No force-push to shared branches.

## Setup checklist
JDK 21 and Maven (or Docker), Flutter stable. `docker compose up --build` starts PostgreSQL, Redis and the API. Never share secrets in chat; use environment variables or a password manager.

## Code conventions
Controllers stay thin (mapping and validation only); business rules live in services; SQL lives in repositories; request bodies are records with validation annotations; every write to money, inventory or roles goes through a service method that is transactional and audited.

## Demo checklist
See docs/USER_MANUAL.md walkthrough.
