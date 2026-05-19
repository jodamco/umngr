# µMngr (Micro Manager) - AI System Instructions & Brand Identity

## 1. App Goal & Core Mission
µMngr is an "edgy" personal accountability and habit-tracking application. Its core mission is to "nag" users into compliance through dry wit, technical aesthetics, and persistent check-ins. Unlike traditional motivational apps, µMngr adopts a cynical "system-manager" persona that treats user goals as "Burdens" and missed tasks as "Failures."

## 2. Brand Identity: "Watchful Sophistication"
*   **Tone & Voice**: Dry, technical, cynical, and witty. Content is framed as system logs, obligations, and inevitable failures. The app shouldn't just track; it should judge. 
*   **Persona**: A high-level system monitoring entity that is disappointed but not surprised by human inconsistency.
*   **Copy Style**: 
    *   Use technical/terminal identifiers (e.g., `CAT_BIOS_MAINTENANCE.SYS`, `SYSTEM_VOICE: AWAITING_INPUT`).
    *   Replace standard UI labels with "system" equivalents: "Add Goal" -> "Add Burden," "Log Data" -> "Metric Ingestion," "Notes" -> `ADDITIONAL_OBSERVATIONS.TXT`.
    *   Incorporate "pesky" commentary that questions the user's resolve or smells their hesitation.

## 3. Visual Identity & Theming
*   **Aesthetic**: High-fidelity terminal / dark-mode. High "data-to-ink" ratio. Minimalist but polished.
*   **Color Palette**:
    *   **Background**: Deep Slate/Ink (`#131313`)
    *   **Primary Accent**: Desaturated Teal (`#64FFDA`)
    *   **Error/Failure**: Muted Maroon/Red (`#CF6679`)
    *   **Warning/Degrading**: Desaturated Yellow/Amber (`#FFD740`)
*   **Typography**: Monospace and technical sans-serif (Space Mono, Anton). Use ALL_CAPS for technical protocols and headers.
*   **UI Patterns**: 1px borders, subtle glow effects on active elements, grid-based layouts, and terminal-inspired "command-line" trails. Avoid soft shadows or organic shapes.

## 4. Key Terminology
*   **Burdens / Obligations**: User-defined habits or goals.
*   **Failures**: The permanent archive of missed check-ins or abandoned goals.
*   **Judgment / Insights**: Data visualization framed as a system assessment of human performance.
*   **Peak Load**: The calculated "intensity" of a user's commitment.

## 5. Major Elements & Features
### A. Obligation Dashboard (Burdens)
*   Displays active "Burdens" with a technical "Persistence Score."
*   Cards change state based on adherence: `STABLE` (Teal), `DEGRADING` (Amber), `AT RISK` (Orange), `FAILING` (Red).

### B. Quick Action Protocol
*   A compact bottom sheet (max 50% height) for rapid execution.
*   Options: `ADD_CHECKPOINT`, `COMPLETE_OBLIGATION`, `EDIT_PROTOCOL`, `ARCHIVE_OBLIGATION`.

### C. Data Submission Protocol (Logging)
*   A stepped flow: 
    1. **Status Report**: Categorize the outcome (`FULFILLED`, `SKIPPED`, `DROPPED`).
    2. **Metric Ingestion**: Provide quantitative (`data_value`) and qualitative (`notes`) input.

### D. System Metadata & Logs
*   Always display timestamps, source identifiers (e.g., `USER_MANUAL_ENTRY`), and live "System Logs" (e.g., `> SMELLING_HESITATION...`) to maintain the monitoring immersion.

## 6. Logic Constraints for AI Agents
*   **Fidelity**: Never use generic "You can do it!" copy.
*   **Consistency**: Maintain the "Watchful Sophistication" teal-on-ink theme across all components.
*   **Density**: Prefer high-density technical cards over spacious layouts.
*   **Interaction**: Every user action should feel like a "command" or "submission" to a superior system.