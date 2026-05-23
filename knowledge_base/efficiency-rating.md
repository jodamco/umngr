# Efficiency Rating

## Overview

The Efficiency Rating is a percentage shown on the Goals view that measures how consistently the user is completing checkpoints across all their active goals.

## How It Works

### Step 1 — Calculate Total Expected Occurrences

For each goal, we count how many occurrences are expected based on its cycle type:

| Cycle | Contribution |
|-------|-------------|
| `daily` | `occurrences` field (times per day). Falls back to `checkpoints.length` when `occurrences` is null. |
| `weekly` / `bi_weekly` | `activeDays.length` (number of active days per week/bi-week). Falls back to 1 when empty. |
| `monthly` | Always 1 (fires once per month on `dayOfMonth`). |
| _(unknown)_ | 1 as a safe fallback. |

**Example:**  
- 1 monthly goal → contributes **1**  
- 1 daily goal with `occurrences = 3` → contributes **3**  
- **Total expected = 4**

The sum across all goals gives the `totalOccurrences`.

### Step 2 — Count Actual Checkpoint Events

`totalEvents` = sum of `eventCount` for every goal.  
`eventCount` is stored on `GoalModel` and populated from the `goals_details` DB view.

### Step 3 — Compute the Percentage

```
efficiency = (totalEvents / totalOccurrences) × 100
```

### Step 4 — Clamping Rules

| Raw Value | Displayed Value |
|-----------|----------------|
| `< 0` | **0%** |
| `> 100` | **99%** _(never shows a perfect 100%)_ |
| `0 – 100` | Raw value |

Returns `0` when `totalOccurrences == 0` (no goals configured).

## Implementation

| File | Role |
|------|------|
| `lib/features/goals/bll/efficiency_bll.dart` | `EfficiencyBLL` — two methods: `calculateTotalOccurrences(goals)` and `calculateEfficiency(goals)` |
| `lib/features/goals/views/goals_view.dart` | `_GoalsList.build()` — instantiates `EfficiencyBLL`, computes efficiency, passes it to the card |
| `lib/features/goals/views/widgets/efficiency_rating_card.dart` | `EfficiencyRatingCard` — accepts `efficiencyPercentage` (0–99) and renders the progress bar and label |

## Key Decisions

- **Pure calculation**: `EfficiencyBLL` has no DB dependencies. It operates purely on the `List<GoalModel>` already fetched by `GoalsView`, avoiding an extra async round-trip.
- **No memoisation needed**: The calculation is O(n) and runs once per rebuild of `_GoalsList`.
- **Capped at 99%**: Designed to always give the user something to strive for; 100% is intentionally unreachable in the UI.
