# Profile Completion & Trust Signals Test

## User Story
As a verified trader, I want to complete my profile with identification and wallet details so that other members trust engaging with me.

## Test Preconditions
- Authenticated user account with email verified.
- Access to staging S3/GCS bucket for media uploads.
- Sample government ID file and avatar image available for upload.

## Test Steps
1. Log in with a verified account and navigate to the profile completion flow.
2. Upload a new avatar image, ensuring progress feedback and cropping tools behave as expected.
3. Submit government ID and confirm secure upload (HTTPS, masked preview, audit log entry).
4. Add wallet details and social links, validating field-level error messaging for invalid formats.
5. Submit the profile and observe confirmation messaging and updated trust indicators on the profile overview.
6. Refresh the session or log in from another device to confirm persisted completion status.
7. Attempt to edit restricted fields (e.g., government ID) and ensure the system requires re-verification or admin approval.

## Acceptance Criteria
- Avatar, ID, and wallet fields enforce validation rules and display clear error states when invalid data is provided.
- Files upload securely to the configured storage bucket with server-side confirmation.
- Profile completion status updates in real time, surfacing badges or progress meters in the UI.
- Subsequent sessions reflect completed profile data without requiring re-entry.
- Sensitive fields follow security constraints (e.g., read-only after submission unless re-verified).
