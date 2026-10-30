# UI Mockups & Design System Rule

Whenever making UI, layout, or visual component changes across TimeEcho, always use the Storybook mockup catalog in the [`time-echo/mockups`](https://github.com/time-echo/mockups) repository as the canonical reference:

- **Consult Mockups First**: Before modifying or creating any UI component, layout, or page, inspect the corresponding story in the [`time-echo/mockups`](https://github.com/time-echo/mockups) repository (`src/stories/Tier{1..5}-*.stories.tsx`, or run `pnpm storybook` on port `6006`).
- **Tier Mapping**:
  - **Tier 1 – UI Primitives**: `PaperSheet`, `ArchivalFolder`, `PostmarkStamp`, `WaxSeal`, `DualEmotionalBar`, `CountdownBadge`, `LinedPaperCanvas`, `RadialProgress`
  - **Tier 2 – Stamps**: Stamp catalog across all categories, sizes (`sm`, `md`, `lg`, `xl`), postmark overlays, and `StampPickerModal`
  - **Tier 3 – Layout**: `ArchivalHeader` and `AppShell` (public and authenticated shells)
  - **Tier 4 – Capsules**: `CapsuleCard` states and `LetterComposerForm`
  - **Tier 5 – Pages (Figma Frames)**: `Landing-V2`, `Composer-Full`, `Letter-Sealed`, `Letter-Opened`, `Vault-Grid`, `Analytics-Summary`, `Settings-Sections`
- **Design System Synchronization**: Keep design tokens, typography, translations, and shared UI components aligned with the [`time-echo/mockups`](https://github.com/time-echo/mockups) repository.
