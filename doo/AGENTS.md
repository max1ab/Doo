# Code Style

- Use SwiftUI as the default UI layer; introduce AppKit only for macOS-specific window or title bar behavior that SwiftUI does not model cleanly.
- Keep types small and focused. Prefer one primary responsibility per file or type, such as view composition, persistence, or window bridging.
- Use `struct` for views and lightweight data models, and `final class` for reference-type services and coordinators.
- Prefer `private` for implementation details and keep the public surface minimal.
- Name functions and state clearly by behavior, for example `loadCurrentDayItemsIfNeeded`, `moveToEndIfDone`, and `storageFileURL`.
- Use `@State`, `@Binding`, `@FocusState`, and `@Environment` directly in views; keep state local unless there is a clear need to extract it.
- Handle early-exit conditions with `guard` and keep branching shallow.
- Prefer value transformations with standard library chaining like `map`, `filter`, and `compactMap` when it keeps the code straightforward.
- Keep formatting consistent with the current codebase: 4-space indentation, opening braces on the same line, and multi-line argument lists when a call would otherwise become cramped.
- Favor concise expressions and straightforward control flow over abstraction-heavy patterns.
- Keep user-facing strings in the existing style used by the app: short, direct, and primarily Chinese for UI labels.
- Persist todo history in Markdown using the existing `yyyy-MM-dd` section format and `- [ ]` / `- [x]` item syntax.
