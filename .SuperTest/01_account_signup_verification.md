# Account Signup & Email Verification Test

## User Story
As a prospective trader, I want to sign up with my email address and verify it so that I can start using SwapWing securely.

## Test Preconditions
- Staging environment available with access to signup API endpoint.
- Transactional email service connected and capable of sending messages.
- Test inbox accessible for verification emails.

## Test Steps
1. Launch the SwapWing app in staging and navigate to the signup screen.
2. Enter a unique email address, strong password, and required profile fields.
3. Submit the form and observe client-side validations and API response handling.
4. Check the test inbox for the verification email and ensure it arrives within 2 minutes.
5. Click the verification link and confirm the backend marks the account as verified.
6. Attempt to log in with the verified account and navigate to an authenticated area.
7. Attempt to access authenticated areas prior to verification to confirm access is blocked with a helpful prompt.
8. Trigger a resend verification email and ensure the prior token becomes invalid.

## Acceptance Criteria
- Signup form enforces mandatory fields and displays actionable error messaging on invalid input.
- API responds with a success payload that informs the user to verify their email.
- Verification email contains a valid, expiring token and accurate branding.
- Verification link activates the account and redirects to a confirmation state in app or browser.
- Users cannot access authenticated features until verification completes; blocked users see guidance to verify or resend.
- Resent verification replaces previous tokens, and only the latest link can be used successfully.
