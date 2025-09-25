# Journey Composer & Follower Notifications Test

## User Story
As a storyteller documenting my trade-up progress, I want to compose journeys with draft steps and notify followers when new updates publish.

## Test Preconditions
- Authenticated user with permission to create journeys.
- Existing follower accounts subscribed to notifications.
- Journey API endpoints available for drafts, publishing, and notifications.

## Test Steps
1. Open the journey composer and create a new draft, filling in title, summary, and hero media.
2. Add multiple steps with narrative notes, timestamps, and optional media attachments; save progress between steps.
3. Exit the composer to confirm the draft persists and appears in the drafts list with last-edited metadata.
4. Resume the draft, preview the full journey, and publish it.
5. Verify the published journey appears in the public journeys feed with accurate ordering of steps and media.
6. Confirm followers receive in-app notifications and, where enabled, push notifications announcing the new step.
7. Review notification preference settings to ensure opt-outs suppress alerts for respective followers.
8. Edit a published journey step (if allowed) to validate versioning or audit logs capture the change.

## Acceptance Criteria
- Drafts autosave or persist on manual save, and re-opening restores all content accurately.
- Publishing transitions the journey from draft to live status and removes it from the drafts list.
- Public feed displays the journey with correct metadata, including author, steps, and timestamps.
- Followers configured for notifications receive timely alerts in-app and via push, respecting user preferences.
- Notification logs capture delivery status for QA verification.
- Any edits to published content follow the product rules (e.g., require republish, show edited labels, or block edits).
