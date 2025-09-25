# Feedback Capture, Notification Preferences & Analytics Test

## User Story
As the product team, we want to collect actionable feedback, respect notification preferences, and monitor key analytics so that we can iterate on SwapWing effectively.

## Test Preconditions
- Feedback API endpoint and support inbox integration active.
- Notification preference service accessible for toggling push/email settings.
- Analytics pipeline connected to dashboard or log sink for verification.

## Test Steps
1. From the profile or settings area, open the feedback form and submit a detailed suggestion including sentiment and contact consent.
2. Confirm client validations (min/max length, contact info) run before submission and that success messaging appears.
3. Check the support inbox or ticketing integration to ensure the submission is received with metadata and device context.
4. Navigate to notification settings and toggle push categories (listings, challenges, journeys). Verify the preferences persist across sessions.
5. Trigger a sample notification for each category and ensure only opted-in channels deliver messages.
6. Perform key user flows (signup, search, listing creation, journey publish) and monitor analytics events firing with correct payloads.
7. Validate analytics dashboards or logs reflect the events within expected latency and segment by environment (staging vs. production).
8. Submit additional feedback entries without contact consent to verify privacy handling and filtering in the support system.

## Acceptance Criteria
- Feedback submissions validate required fields, store sentiment/contact preferences, and reach the support inbox with traceability IDs.
- Notification preference toggles persist server-side and immediately impact subsequent notification deliveries.
- Analytics events cover all critical flows with accurate metadata and appear in monitoring tools within SLA.
- Opt-out users do not receive push notifications for disabled categories.
- Feedback data is accessible for triage while honoring privacy choices.
