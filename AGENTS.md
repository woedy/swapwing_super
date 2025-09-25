# SwapWing Development Guide

## Vision Snapshot
SwapWing blends a barter marketplace with community storytelling. Traders list goods or services, negotiate progressive "trade-up" journeys, and rally around community challenges. The Flutter client already demonstrates these journeys with seeded data, while the Django backend establishes accounts, profiles, notifications, and league content foundations. The immediate goal is to transform this concept into an end-to-end, production-ready experience.

## Guiding Product Pillars
1. **Trustworthy Trading** – Verified identities, transparent listings, and safe negotiation flows.
2. **Story-Driven Journeys** – Rich narrative tooling for trade-up series, episodic content, and community followership.
3. **Engaged Community** – Challenges, leaderboards, and social discovery that highlight trader achievements.
4. **Scalable Foundations** – Modular architecture, observable systems, and CI/CD practices that let the team iterate confidently.

## Delivery Approach
* Work feature-by-feature via user stories and acceptance criteria.
* Keep Flutter and Django work in sync—design APIs first, document them, and build stubs/tests before wiring UI.
* Favor feature flags and mocked data for incomplete backends so we can ship incrementally without blocking other squads.
* Maintain a living task board from the checklist below; update it as we learn.

## User Stories & Acceptance Criteria
The following stories represent the next phase of work. Stories are grouped by epic and each includes acceptance criteria (AC) to validate success.

### Epic A – Account & Identity
1. **As a prospective trader, I want to sign up and verify my email so that I can access SwapWing securely.**
   * AC1: Email/password registration endpoint issues a verification email with expiring token.
   * AC2: Flutter signup screen validates fields client-side and handles API errors gracefully.
   * AC3: Users cannot access authenticated areas until verification succeeds; unverified accounts prompt re-send.

2. **As a trader, I want to complete my profile with identification and wallet details so others trust me.**
   * AC1: Profile API supports uploading avatar, government ID, and adding social links.
   * AC2: Backend validates required documents and stores securely (S3/Cloud Storage).
   * AC3: Flutter profile flow reflects completion status and prevents submission without mandatory fields.

### Epic B – Marketplace Listings
3. **As a trader, I want to browse and filter listings so I can find relevant swap opportunities.**
   * AC1: Listings API supports pagination, category filters, and keyword search.
   * AC2: Home/Search tabs in Flutter render real API data with loading, empty, and error states.
   * AC3: Analytics event fires on each search to capture demand signals.

4. **As a trader, I want to create a listing with media and desired trade criteria so others can engage me.**
   * AC1: Create listing form supports multiple images/video uploads with progress feedback.
   * AC2: Backend validates item condition, category, and desired outcomes; rejects incomplete submissions.
   * AC3: Successful submission returns listing ID and surfaces in My Listings within 5 seconds.

### Epic C – Trade Journeys & Challenges
5. **As a storyteller, I want to document my trade-up journey so followers can track each step.**
   * AC1: Journey API manages steps with media, timestamps, and narrative notes.
   * AC2: Flutter journey composer allows draft saving and publishing with preview.
   * AC3: Followers receive in-app notification when a new step publishes.

6. **As a community member, I want to participate in challenges and see leaderboards so I stay motivated.**
   * AC1: Challenge API exposes enrollment, progress updates, and ranking endpoints.
   * AC2: Challenge detail screen shows real-time standings via polling/websockets.
   * AC3: Push notification triggers when rankings change tier (top 3 / top 10).

### Epic D – Foundations & Ops
7. **As an engineer, I want automated testing and CI so regressions are caught before release.**
   * AC1: Backend includes unit + API tests in GitHub Actions with >80% coverage on new code.
   * AC2: Flutter pipeline runs analyzer, tests, and build checks on PR.
   * AC3: Feature flags documented with rollout strategy in repo wiki.

8. **As a product team, we want telemetry and feedback loops so we can iterate on real usage.**
   * AC1: Instrument core flows with analytics (events, funnels) and document dashboards.
   * AC2: In-app feedback module captures user suggestions and routes to support inbox.
   * AC3: Monthly product review includes metrics review and backlog grooming notes.

## Task Checklist
Use this as a living roadmap. Check items off as they complete, and append new items when scope evolves.

### Platform Alignment
- [x] Finalize API contract between Flutter and Django for accounts, listings, journeys, and challenges. (Documented in `docs/api_contract.md`.)
- [x] Establish shared domain model documentation (ERD, sequence diagrams). (See `docs/domain_model.md`.)
- [x] Configure staging environments for client and server with seeded data. (See `docs/staging_environment.md` and `swapwing_backend/accounts/management/commands/seed_staging.py`.)

### Backend (Django)
- [x] Implement email verification flow with Celery + transactional email provider.
- [x] Harden `user_profile` storage (S3/GCS integration, validation).
- [x] Build listings CRUD endpoints with filters and tests.
- [x] Implement journey management endpoints with media support.
- [x] Create challenge enrollment, progress, and leaderboard services (consider Channels for realtime).
- [x] Set up DRF viewsets with Swagger/OpenAPI documentation.
- [x] Add pytest + coverage, enforce via CI.

### Frontend (Flutter)
- [x] Replace sample auth with live API integration and secure token storage.
- [x] Wire listings Home/Search to backend with skeleton loaders and error states.
- [x] Build create-listing wizard with media picker/upload feedback.
- [x] Implement journey composer with drafts and previews.
- [x] Add challenge participation flows with real-time updates.
- [x] Integrate analytics/events instrumentation.
- [x] Add in-app feedback module and push notifications.

### Operations & QA
- [ ] Define branching, PR review, and release cadence in CONTRIBUTING.md.
- [ ] Set up GitHub Actions (backend + Flutter) for lint/test/build.
- [ ] Monitor staging with logging/alerting (Sentry, CloudWatch, etc.).
- [ ] Schedule monthly product review rituals with analytics summary template.

---
Maintain this file as our single source of truth for priorities. Update user stories, acceptance criteria, and checklist items as we discover new requirements or validate assumptions.
