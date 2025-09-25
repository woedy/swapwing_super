# Listing Creation & Publication Test

## User Story
As a trader ready to offer an item or service, I want to create a listing with media and trade preferences so that other members can engage me.

## Test Preconditions
- Authenticated user with verified profile and media upload permissions.
- Device with camera roll access or sample media files for testing.
- Backend create listing endpoint operational with validation rules.

## Test Steps
1. Navigate to the create listing wizard and review step-by-step instructions.
2. Complete the basics step, entering title, category, condition, and desired trade outcomes; validate inline field checks.
3. Move to the details step, invoking AI helper suggestions and ensuring recommendations render and can be accepted or dismissed.
4. Upload multiple photos/videos, monitoring upload progress indicators and retry behavior for failures.
5. Proceed to the review step and ensure a preview card accurately reflects entered data and media ordering.
6. Submit the listing and confirm the success toast/modal references the new listing ID.
7. Verify the listing appears in "My Listings" and the public feed within 5 seconds of submission.
8. Attempt to submit incomplete data to confirm server-side validation errors are surfaced with actionable guidance.

## Acceptance Criteria
- Wizard enforces completion of required fields before advancing to subsequent steps.
- AI helper interactions are optional and do not block submission; accepted suggestions populate detail fields correctly.
- Media uploads show progress, support retry on failure, and preserve order chosen by the user.
- Successful submission returns the new listing ID, triggers analytics, and displays confirmation messaging.
- Newly created listing propagates to personal and public feeds promptly with accurate metadata.
- Validation failures return descriptive errors without clearing valid inputs.
