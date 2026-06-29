# Project: Argity Turnos Rename

## Architecture
- Flutter Client Application (Kali-Studio-Client) targetting Web, Android, iOS, macOS.
- Shared Supabase backend.
- Modifies user-facing text, configuration display names, page titles, and public assets to "Argity Turnos" while preserving internal code identifiers (package names, directory names, internally used constants/variables).

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Locate old names | Search codebase for occurrences of "Kali Studio", "Minerva", "KaliStudio", "kali-studio" | None | DONE |
| 2 | Codebase rename | Replace names in UI text, configs, and assets, keeping internal code identifiers | M1 | DONE |
| 3 | Build & Verification | Compile and build the Flutter app and run unit tests | M2 | DONE |

## Interface Contracts
- This is a global renaming refactoring. The interfaces of functions, variables, and database RPCs remain unchanged to avoid breaking interactions with Kali-Studio-Admin and Supabase.
