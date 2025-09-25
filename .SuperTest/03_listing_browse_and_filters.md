# Listing Browse, Filter, and Search Test

## User Story
As a trader exploring swap opportunities, I want to browse, filter, and search listings so that I can find relevant matches quickly.

## Test Preconditions
- Seeded staging data with at least 30 listings across multiple categories and conditions.
- Backend listings API available with pagination, filtering, and keyword search enabled.
- Analytics service configured to capture search events.

## Test Steps
1. Launch the Home tab and confirm skeleton loaders display while data is fetched.
2. Verify the first page renders real API data including owner avatar, title, category, and media preview.
3. Trigger pull-to-refresh and confirm the list refreshes with updated timestamp and no duplicate entries.
4. Scroll through multiple pages to validate infinite scroll or pagination controls load additional results without stutter.
5. Open the Search tab and enter a keyword, confirming debounced requests and loading indicators behave correctly.
6. Apply category and condition filters, and adjust sort order to validate API query parameters and UI chips update.
7. Observe analytics logs or monitoring dashboard to confirm search events are captured with filter context.
8. Force an API error (e.g., disable network) to ensure error states display retry options and helpful messaging.
9. Clear filters to confirm the default feed is restored and empty states render when no results match criteria.

## Acceptance Criteria
- Home and Search tabs consume live data, showing skeleton, empty, and error states appropriately.
- Pagination delivers consistent results with no duplicates or gaps, and refreshing maintains list integrity.
- Filters and sorting accurately translate to backend query parameters and reflect in the UI selections.
- Analytics event fires for each search submission with relevant metadata (keyword, filters, result count).
- Error scenarios display clear recovery options, and empty states encourage alternative actions.
