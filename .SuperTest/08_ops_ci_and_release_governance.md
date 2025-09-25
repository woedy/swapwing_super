# Operations, CI/CD & Release Governance Test

## User Story
As the engineering operations lead, I want confidence that branching strategy, CI pipelines, and release rituals keep SwapWing stable and predictable.

## Test Preconditions
- CONTRIBUTING.md updated with branching and release processes.
- GitHub Actions workflows configured for backend and Flutter projects.
- Monitoring and alerting tools available for staging environment.

## Test Steps
1. Review CONTRIBUTING.md to ensure branching strategy, PR review requirements, and release cadence are clearly documented.
2. Create a feature branch locally, push to GitHub, and open a pull request to validate required status checks and reviewer rules trigger.
3. Confirm CI pipelines run linting, unit tests, and build steps for both backend and Flutter projects, and inspect artifacts/logs.
4. Introduce a failing test intentionally to ensure CI fails and communicates actionable errors to developers.
5. Merge a successful PR into the staging branch and verify automated deployment triggers with status updates in the team channel.
6. Validate staging monitoring dashboards (Sentry, CloudWatch) capture logs and surface alerts for simulated errors.
7. Conduct a mock monthly product review by compiling analytics summary templates and retro notes, ensuring documentation is stored in the designated location.

## Acceptance Criteria
- CONTRIBUTING guidelines are discoverable, prescriptive, and align with team workflows.
- CI/CD pipelines enforce quality gates and block merges on failures.
- Deployment pipeline updates staging automatically and provides visibility into release status.
- Monitoring surfaces meaningful alerts, and on-call runbooks reference escalation paths.
- Monthly review ritual documentation is accessible and covers metrics, wins, and backlog adjustments.
