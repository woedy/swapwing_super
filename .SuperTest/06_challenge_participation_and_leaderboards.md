# Challenge Participation & Leaderboard Dynamics Test

## User Story
As a community member, I want to enroll in challenges, log progress, and track leaderboards so that I stay motivated to trade actively.

## Test Preconditions
- Challenge API endpoints for enrollment, progress updates, and leaderboard polling/websocket streaming enabled.
- Sample challenge available with multiple seeded participants.
- Push notification service configured for ranking tier changes.

## Test Steps
1. Navigate to the social discovery screen and select an active challenge.
2. Review challenge details, rewards, and rules to ensure copy accuracy and responsive layout.
3. Enroll in the challenge and confirm enrollment status updates immediately in the UI and backend.
4. Log a progress update, including optional media, and observe the simulated real-time feed displaying the new entry.
5. Monitor the leaderboard for position changes, ensuring polling or websocket updates occur within the expected interval.
6. Trigger additional progress entries from test accounts to validate live updates and ranking animations.
7. Confirm push notifications fire when the user moves into the top 3 or top 10 tiers, respecting opt-in status.
8. Leave the challenge and verify standings update accordingly and notifications cease.

## Acceptance Criteria
- Enrollment, progress logging, and leaderboard updates succeed with responsive UI feedback.
- Real-time updates appear without requiring manual refresh, and historical activity remains accessible.
- Leaderboard ranking logic matches backend calculations and handles ties deterministically.
- Push notifications respect user preferences and are sent when rank thresholds are crossed.
- Leaving a challenge reverts the user to a non-participant state and removes them from leaderboards promptly.
