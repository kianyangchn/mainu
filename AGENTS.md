# Repository Guidelines

## Project Structure & Module Organization
Keep the primary Xcode project in `App/mainu.xcodeproj`. Feature code belongs under `App/Sources/`, with shared modules split into `Modules/<FeatureName>/Sources/` and mirrored tests in `Modules/<FeatureName>/Tests/`. Place assets in `Resources/` (including `.xcassets`, storyboards, and localized strings) and automation scripts in `Tools/`. Keep files focused; if a Swift file grows past ~200 lines, factor it into smaller types or extensions.

## Build, Test, and Development Commands
- `xcodebuild -scheme mainu -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' build`: verify the app compiles without launching the simulator UI.
- `xcodebuild -scheme mainu -destination 'platform=iOS Simulator,name=iPhone 15' test`: run the complete unit and UI test suite; capture simulator logs for failures.
- `swift test`: execute Swift Package tests for modules under `Modules/`.
- `mint run swiftformat .` / `mint run swiftlint lint`: format and lint the codebase prior to opening a PR. Commit the `Mintfile` once tooling is introduced so CI can install the same versions.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines: PascalCase types, camelCase methods and properties, SCREAMING_SNAKE_CASE constants. Use four-space indentation and avoid trailing whitespace. Prefer protocol-oriented designs and lightweight value types. Organize SwiftUI/UIKit code so views stay declarative and business logic moves into view models or modules.

## Testing Guidelines
Name XCTest classes `<Subject>Tests` and UI suites `<Subject>UITests`. Mirror the production folder structure inside `Tests/`. Maintain ≥80% coverage for logic-heavy modules and ensure each new feature has at least one integration test. Run `xcodebuild ... test` locally before pushing changes and share the simulator destination and outcome in PR notes.

## Commit & Pull Request Guidelines
Adopt Conventional Commits (e.g., `feat: add profile screen`, `fix: handle login retry`). Limit each commit to a single concern and document user-visible changes in the body when helpful. Pull requests must include a concise summary, testing commands run, linked issue or ticket, and UI evidence (screenshots or recordings) when visual changes occur. Request review from an iOS peer and wait for CI to pass before merging.

## Agent Workflow Tips
Confirm the workspace stays within the repository conventions before making changes. When in doubt, search existing modules for examples (`rg "ViewModel" Modules`). Prefer modifying local code rather than introducing new dependencies, and keep automation scripts inside `Tools/` for visibility.
