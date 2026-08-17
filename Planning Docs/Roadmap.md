# Do & Due — Full Project Recap & Handoff

**Project:** Do & Due
**Platform:** iPhone / iOS
**Language:** Swift
**IDE:** Xcode
**Architecture:** SwiftUI + SwiftData
**Current status:** MVP actively being built and running successfully

---

# 1. The Core Idea

**Do & Due is a simple personal task/reminder app focused on things that need to happen repeatedly.**

The central idea is that not every task is a conventional to-do item.

Some things are:

> "I need to do this once."

Others are:

> "I need to do this again after I do it."

And others are:

> "I need to do this on a specific schedule."

Examples:

* Change air filter
* Flush water heater
* Replace smoke detector batteries
* Clean dryer vent
* Take car for inspection
* Renew registration
* Pay a bill
* Call someone
* Buy something
* Check something every month

The key differentiator is **relaxed recurrence vs. fixed recurrence**.

### Relaxed recurrence

The next occurrence is based on when the user actually completes the task.

Example:

> Change air filter — every 3 months

If completed August 15:

> Next due November 15

If actually completed August 20:

> Next due November 20

This is useful for maintenance and other tasks where the interval matters more than the calendar date.

### Fixed recurrence

The task happens according to the calendar regardless of when it was last completed.

Example:

> Check smoke detectors — 1st of every month

If completed August 4, the next occurrence is still:

> September 1

This distinction is central to Do & Due.

---

# 2. Product Philosophy

The app should be:

* Extremely simple
* Fast to understand
* Visually clean
* Low-friction
* Focused on what needs to happen
* More useful than Apple's basic Reminders for recurring maintenance
* Not overloaded with project-management features

The user should be able to open Do & Due and immediately understand:

> **What do I need to do today?**

The app should not feel like a complicated productivity system.

---

# 3. MVP Requirements

The MVP was intentionally kept small.

## Task types

### 1. One-off

A task that happens once.

Example:

> Buy new smoke detector

When completed, it disappears from active tasks.

---

### 2. Relaxed recurring

Recurring based on completion date.

Examples:

* Every 1 month
* Every 3 months
* Every 6 months
* Every 1 year

The recurrence UI currently uses:

```text
Every [1] [month]
```

The interval is configurable.

---

### 3. Fixed recurring

Recurring according to a calendar schedule.

Current conceptual options:

* Weekly
* Monthly
* Yearly

Examples:

```text
Every Monday
```

```text
1st of every month
```

```text
August 15 every year
```

The task's next due date is calculated from the fixed schedule rather than its completion date.

---

# 4. Core Views

## Today

The primary screen.

It should show:

### Overdue

Tasks whose due date is before today.

### Today

Tasks due today.

### Upcoming

Future tasks.

The current implementation limits Upcoming to the first 10 tasks.

If there are no tasks due today, the app explicitly displays:

> **All done for today!**

This was intentionally chosen over simply shifting upcoming tasks upward because the empty state communicates completion much more clearly.

---

# 5. All Tasks

A second view showing all active tasks.

Current tab structure:

```text
Today
Tasks
```

Today is the primary workflow.

Tasks is the complete active-task list.

Completed one-off tasks aren't currently displayed as active tasks.

---

# 6. Task Creation / Editing

The current editor includes:

### Basic information

* Title
* Notes

### Repeat

* One-off
* Relaxed recurring
* Fixed recurring

### Due

* First due date

### Reminder

Reminder functionality is being built into the task model.

---

# 7. Reminder System

The app has a `NotificationManager`.

It uses:

```text
UserNotifications
```

The current conceptual reminder options include:

* None
* At 9 AM
* One day before
* One week before

The system schedules a notification for the task's next due date.

When a recurring task is completed, its next occurrence is calculated and the notification is rescheduled.

One-off tasks have their notification cancelled when completed.

---

# 8. Data Model

The app uses **SwiftData**.

## `Task`

Current model includes:

```text
id
title
notes

taskTypeRaw
reminderRaw

recurrenceInterval
recurrenceUnitRaw

fixedFrequencyRaw
fixedWeekday
fixedDayOfMonth
fixedMonth
fixedDay

dueDate

createdAt
updatedAt

completions
```

Enums are stored using raw values rather than directly as SwiftData properties.

The model exposes computed properties:

```text
taskType
reminder
recurrenceUnit
fixedFrequency
```

---

# 9. TaskCompletion

There is a separate SwiftData model:

```text
TaskCompletion
```

with:

```text
id
completedAt
task
```

The relationship is:

```text
Task
  └── completions
        └── TaskCompletion
              └── task
```

The relationship uses cascade deletion.

This gives us a foundation for eventually showing task history.

---

# 10. Current Architecture

Current basic structure:

```text
DoAndDueApp
   │
   └── RootView
         │
         ├── SplashView
         └── TabView
              ├── TodayView
              └── AllTasksView

TaskEditorView
      │
      └── TaskStore
             │
             ├── create
             ├── complete
             ├── update notification
             └── delete

TaskStore
      │
      ├── SwiftData / ModelContext
      │
      └── NotificationManager

RecurrenceEngine
      │
      ├── next relaxed date
      └── next fixed date
```

The app uses:

* SwiftUI for UI
* SwiftData for persistence
* UserNotifications for reminders
* Separate recurrence logic
* `TaskStore` for task operations

---

# 11. Current Files

The project currently has at least these major files:

```text
DoAndDueApp.swift
RootView.swift
SplashView.swift

Task.swift
TaskCompletion.swift
TaskStore.swift
RecurrenceEngine.swift
NotificationManager.swift

TodayView.swift
AllTasksView.swift
TaskEditorView.swift
TaskRow.swift
AllDoneView.swift
DoAndDueStyle.swift
```

There may be additional supporting enum/model files.

---

# 12. Current Progress

The app currently successfully:

### Tasks

* Creates tasks
* Saves tasks to SwiftData
* Displays tasks
* Edits tasks
* Deletes tasks
* Completes tasks

### Recurrence

* Supports one-off
* Supports relaxed recurring
* Supports fixed recurring
* Calculates future dates

### UI

* Today view
* Overdue section
* Today section
* Upcoming section
* "All done for today!" empty state
* All Tasks view
* Add task flow
* Edit task flow
* Delete confirmation

### Persistence

SwiftData is working correctly.

We confirmed this by inserting a task and fetching it back from the same `ModelContext`.

---

# 13. Important Debugging History

We encountered a significant SwiftData development issue.

After modifying the SwiftData model, the simulator retained an old persistent store.

Symptoms:

```text
TASK SAVED
...
TASKS IN DATABASE: 0
```

The code appeared to save successfully, but the object didn't persist.

Deleting the Do & Due app from the simulator and rebuilding fixed it:

```text
TASKS IN DATABASE: 1
```

### Important lesson

During development, if the SwiftData schema changes and objects suddenly stop persisting:

**Delete the app from the simulator and rebuild before rewriting working persistence code.**

This was a stale development store, not a fundamental architecture problem.

---

# 14. Important Swift Naming Issue

The SwiftData model is named:

```swift
Task
```

Swift concurrency also has a type named:

```swift
Task
```

This caused a number of confusing compiler errors when we attempted to use:

```swift
Task {
    ...
}
```

inside `TaskStore`.

We ultimately avoided that entire problem by keeping `TaskStore` synchronous and using the UserNotifications completion-handler APIs.

### Current rule

Do not casually introduce Swift concurrency `Task {}` inside code where the SwiftData model `Task` is in scope.

The current notification architecture avoids needing it.

---

# 15. What We Deliberately Do NOT Want

These were explicitly considered and rejected for the foreseeable future:

### Apple Watch

Not needed.

### Focus Modes

Not needed.

### Family sharing

Not needed.

The product should remain focused on individual personal task/maintenance management.

---

# 16. Post-MVP Features / Long-Term Roadmap

These are things we discussed as valuable eventually, but they are **not required for MVP**.

## Home Screen Widget

This is one of the highest-value future features.

The user should be able to glance at their iPhone Home Screen and see something like:

```text
LOOP

TODAY

○ Change air filter
○ Water plants
○ Pay electric bill

2 more...
```

Potential widget sizes:

### Small

A simple summary:

```text
LOOP

3 tasks today
```

### Medium

Several actual tasks:

```text
TODAY

○ Change air filter
○ Water plants
○ Call dentist
```

### Large

Potentially a more complete Today list.

The widget should emphasize **glanceability**, not recreate the entire app.

---

# 17. UI/UX Improvements We Want Eventually

The UI should feel extremely polished despite the simple functionality.

## Visual hierarchy

The user should immediately see:

1. Overdue
2. Today
3. Upcoming

Completed tasks should visually disappear or animate away rather than cluttering the screen.

---

## Completion animation

Checking a task off should feel satisfying.

Potential behavior:

```text
○ Change air filter
```

becomes:

```text
✓ Change air filter
```

then smoothly disappears or moves into a completed state.

For recurring tasks, the transition could communicate:

> Done → next occurrence scheduled

without making the user think about it.

---

## Better empty states

Today already has:

> **All done for today!**

Future empty states could have similarly useful messaging.

Examples:

```text
Nothing upcoming
```

or

```text
You're completely caught up.
```

But the wording should remain restrained.

---

# 18. Better Task Rows

Task rows are an important part of the UX.

Potential information:

```text
Change air filter
Every 3 months
Due today
```

or:

```text
Flush water heater
Yearly
Due Aug 20
```

The user should understand the task without opening it.

Potential visual indicators:

* Due today
* Overdue
* Tomorrow
* Recurrence type
* Reminder indicator

But avoid excessive metadata.

---

# 19. Smart Date Language

Instead of always showing raw dates:

```text
08/18/2026
```

Do & Due should eventually say:

```text
Today
Tomorrow
Friday
Next Monday
Aug 24
```

This dramatically improves scanability.

---

# 20. Better Recurrence Creation UX

The current recurrence controls work, but eventually the creation experience should feel more natural.

Instead of exposing too many technical controls immediately, it could use natural language:

```text
Repeat

Every 3 months
```

or:

```text
Repeat

1st of every month
```

The app could show a live preview:

> Next due: November 15

This reduces uncertainty.

---

# 21. Task History

Because `TaskCompletion` already exists, we have a foundation for this.

Eventually a task could show:

```text
Change air filter

Every 3 months

History

Aug 15, 2026
May 15, 2026
Feb 14, 2026
```

This is particularly useful for maintenance.

It also makes Do & Due more than just a to-do list.

---

# 22. Snooze / Reschedule

Potential future feature.

For example:

```text
Snooze
```

Options:

```text
Tomorrow
This weekend
Next week
Choose date
```

This is particularly useful for overdue tasks.

However, the semantics need to be carefully designed because snoozing a **fixed recurring** task should not necessarily change its underlying recurrence schedule.

---

# 23. Quick Add

Eventually, adding a task should be extremely fast.

Potential flow:

```text
+
```

then:

```text
Change air filter
```

and optionally:

```text
Every 3 months
```

The app should minimize the number of taps needed to create a basic task.

---

# 24. Natural-Language Quick Entry

Longer-term possibility:

```text
Change air filter every 3 months
```

Do & Due could parse:

```text
Title:
Change air filter

Type:
Relaxed recurring

Interval:
3 months
```

This would be a significant UX improvement but is definitely beyond MVP.

---

# 25. Categories / Organization

Potential future organization:

* Home
* Car
* Finance
* Health
* Personal
* Work

But this should **not** become a mandatory part of task creation.

Categories should only be introduced if they solve a real organizational problem.

The app's strength is simplicity.

---

# 26. Search

Eventually:

```text
Search tasks
```

Useful once a user has dozens or hundreds of recurring tasks.

Could search:

* title
* notes
* category

---

# 27. Filters

Potential filters:

```text
All
Overdue
Today
Upcoming
Recurring
One-off
```

Again, this is primarily useful at scale.

---


# 31. Widget Roadmap

The Home Screen widget is probably the first major post-MVP feature.

Potential widget functionality:

### Small

```text
TODAY
3 tasks
```

### Medium

```text
TODAY

○ Water plants
○ Change filter
○ Pay bill
```

### Large

```text
TODAY

○ Water plants
○ Change filter
○ Pay bill
○ Call plumber
```

Potential future widget interactions could allow completing a task directly from the widget if the relevant iOS APIs support the desired interaction model.

---

# 32. Notifications Roadmap

Current basic notification support can eventually become more sophisticated.

Potential options:

```text
At 9:00 AM
At due time
1 day before
3 days before
1 week before
```

Potentially recurring reminders.

### Same-time reminder digest

When multiple tasks would notify at the same time, Do & Due should avoid sending a burst of separate alerts. Instead, it should schedule one digest-style local notification for that moment.

Example:

```text
3 tasks due today
Wash dishes, Water plants, and Take vitamins
```

Single-task reminders should still use the task title directly.

The important rule:

**Notifications should be based on the task's current next due date.**

When a task is completed:

```text
Complete
   ↓
Calculate next occurrence
   ↓
Save
   ↓
Cancel old notification
   ↓
Schedule new notification
```

---

# 33. UX Principle for Recurring Tasks

The user should **never have to manually create the next occurrence**.

That's the entire point of Do & Due.

For:

> Change air filter — every 3 months

the user should only ever see:

```text
Change air filter
```

They complete it.

Do & Due handles:

```text
Next due: +3 months
```

automatically.

---

# 34. Architecture Principles Going Forward

We should preserve these principles as the project grows.

### SwiftUI

UI and presentation.

### SwiftData

Persistence.

### TaskStore

Task mutations / application logic.

### RecurrenceEngine

Pure recurrence calculations.

### NotificationManager

Notification scheduling/cancellation.

### Views

Should primarily:

* Display state
* Collect input
* Trigger application actions

They should not contain complicated recurrence logic.

---

# 35. Testing Priorities

Before adding major features, the recurrence system should be tested carefully.

### One-off

Create:

```text
Buy milk
```

Complete → disappears.

### Relaxed monthly

Create:

```text
Change filter
Every 1 month
```

Complete August 15 → next due September 15.

### Relaxed yearly

Complete August 15, 2026 → next due August 15, 2027.

### Fixed monthly

Create:

```text
Check smoke detectors
1st of every month
```

Complete August 4 → next due September 1.

### Fixed weekly

Create:

```text
Water plants
Every Saturday
```

Complete on Monday → next Saturday.

### Fixed yearly

Create:

```text
Car inspection
August 15 every year
```

Complete early/late → next occurrence remains tied to August 15.

### Overdue

Create a task with a past due date.

It should appear under:

```text
Overdue
```

### Notification

Verify:

* notification is scheduled
* completion cancels/reschedules appropriately
* editing due date updates notification
* deleting task cancels notification

---

# 36. Current MVP Definition of Done

I would consider the MVP functionally complete when all of these work reliably:

* [x] Create one-off task
* [x] Create relaxed recurring task
* [x] Create fixed recurring task
* [x] Edit task
* [x] Delete task
* [x] Complete task
* [x] Automatically calculate next recurrence
* [x] Today view
* [x] Overdue view
* [x] Upcoming view
* [x] All Tasks view
* [x] "All done for today!" state
* [x] Persist tasks using SwiftData
* [x] Basic notifications
* [ ] Thoroughly test every recurrence case
* [ ] Thoroughly test notifications
* [ ] Polish task-row UX
* [ ] Polish empty states
* [ ] Test edge cases around dates/months/year boundaries

The last four are more **stabilization/polish** than new functionality.

---

# 37. Things We Should NOT Add to MVP

Do not let scope creep undermine the core product.

Not currently needed:

* Apple Watch
* Focus Modes
* Family sharing
* Complex projects
* Subtasks
* Team collaboration
* Chat
* AI
* Calendar replacement
* Habit tracking
* Gamification
* Social features

The MVP should answer one question extremely well:

> **What do I need to do, and when do I need to do it again?**

---

# 38. Development Process We've Established

Because we're vibe-coding this in Xcode, the safest process is:

### 1. Make one coherent feature change

Don't simultaneously alter the data model, recurrence engine, UI, and notifications unless necessary.

### 2. Build immediately

Catch compiler errors before moving on.

### 3. Test the feature manually

Especially because SwiftData behavior can differ from what the compiler tells us.

### 4. When SwiftData models change

Expect the development database to potentially become stale.

If persistence behaves impossibly:

**Delete the app from the simulator and rebuild before rewriting persistence code.**

### 5. Prefer complete files for substantial changes

We've learned that piecemeal patches can leave old async code or conflicting implementations behind.

For significant architectural changes, provide the **full file**.

---

# 39. Current Known Technical State

The current working stack is:

```text
Swift
SwiftUI
SwiftData
UserNotifications
```

The app's SwiftData container is configured in `DoAndDueApp`:

```swift
.modelContainer(
    for: [
        Task.self,
        TaskCompletion.self
    ]
)
```

`RootView` contains the two-tab interface:

```text
Today
Tasks
```

Persistence has been verified after clearing the stale simulator store.

---

# 40. Where We Should Pick Up Next

The code is now in a working state.

**The next phase should not be another big feature.**

The best next step is:

### Stabilize the MVP

Test:

1. One-off completion
2. Relaxed recurrence
3. Fixed recurrence
4. Monthly edge cases
5. Yearly edge cases
6. Editing recurrence
7. Deleting recurring tasks
8. Notifications
9. App relaunch persistence

Then improve the core UI.

After that, the first major post-MVP feature should probably be:

> **Home Screen widget**

because it directly supports the core Do & Due concept: **seeing what needs to be done without opening the app.**

---

# One-Sentence Product Definition

**Do & Due is a simple iPhone task app for things you need to do once or repeatedly, with recurrence that can either follow the completion date or a fixed calendar schedule, making recurring maintenance effortless.**



### 1. More powerful fixed recurrence

The current fixed recurrence model:

* Weekly
* Monthly
* Yearly

is too restrictive for real-world scheduling.

We should eventually support:

#### Multiple days per week

Examples:

> Every Monday, Wednesday, Friday

> Every Tuesday and Wednesday

> Every weekday

UI could be:

```text
Repeat
Fixed schedule

Days
☑ Mon
☐ Tue
☑ Wed
☐ Thu
☑ Fri
☐ Sat
☐ Sun
```

This should produce a human-readable summary:

> Every Monday, Wednesday, and Friday

#### Custom schedules

Potentially allow combinations such as:

* Every 2 weeks on Monday and Thursday
* Every 3 months on the 1st and 15th
* Every weekday
* Every weekend
* First Monday of every month
* Last Friday of every month

We don't need all of that immediately. The key architectural decision is to make the recurrence system capable of **multiple selected dates**, rather than designing around a single `fixedWeekday`.

I'd change the eventual model from:

```text
fixedWeekday: Int?
```

toward something like:

```text
fixedWeekdays: [Int]
```

with the exact SwiftData representation decided when we implement it.

---

# 2. Siri Integration

**Yes, absolutely.** This is very possible on iPhone.

The modern Apple architecture for this is **App Intents + Siri**.

The eventual experience could be:

> **"Hey Siri, add change air filter to Do & Due."**

Siri adds:

> Change air filter

to Do & Due.

Even better, we could eventually support natural recurrence:

> **"Hey Siri, remind Do & Due to change the air filter every three months."**

or:

> **"Hey Siri, add water the plants to Do & Due every Monday Wednesday and Friday."**

The more sophisticated versions require us to expose Do & Due's task creation functionality as an App Intent and define the parameters Siri can understand.

### Potential Siri commands

**Simple:**

> "Add buy milk to Do & Due."

**With date:**

> "Add call the plumber to Do & Due tomorrow."

**With recurrence:**

> "Add change the filter to Do & Due every three months."

**With fixed schedule:**

> "Add water plants to Do & Due every Monday Wednesday and Friday."

That could become one of the app's genuinely excellent UX features.

---

Also these belong in the roadmap as well:

I'd organize the future features roughly like this:

### Tier 1 — Core UX

* **Better recurrence scheduling**

  * Multiple weekdays
  * Custom schedules
  * Weekdays/weekends
  * More flexible monthly schedules
* **Home Screen widget**
* Better task rows
* Better date language
* Completion animations
* Quick Add
* Better recurrence preview
* Notification digest for same-time reminders

### Tier 2 — Convenience

* **Siri / App Intents**
* Interactive widget actions
* Snooze/reschedule
* Task history
* Search
* Filters

### Tier 3 — Advanced

* Home maintenance templates
* Categories
* Calendar integration
* Natural-language task creation
* Smarter scheduling based on usage

---

# 41. Current Implementation Snapshot — August 15, 2026

The MVP is now validated and the project has moved into final-product polish:

* Core task operations: create, edit, delete, complete, persist with SwiftData.
* Task types: no repeat, repeat after completion, repeat on a fixed schedule.
* Fixed schedule tasks support daily, weekday, weekend, and custom weekday repetition.
* Recurrence edge cases are handled for 31st-of-month schedules and February 29 yearly schedules.
* Notifications are wired through `TaskStore`, schedule only after successful saves, and use predictable 9 AM reminder timing for due-day, day-before, and week-before options.
* Shared presentation helpers now own user-facing task metadata, recurrence summaries, date wording, weekday/month names, and editor previews.
* Today, Tasks, Task Detail, and Task Editor have all received first-pass mockup-aligned styling.
* The editor uses clearer repeat wording: `No repeat`, `After I complete it`, and `On a schedule`.
* Completing a task now shows a checked/struck-through state, light haptic feedback, then a springy disappearance or move to its next scheduled date.

Important development notes:

* `Task` now includes `fixedWeekdaysRaw`. If simulator or device persistence behaves strangely after model changes, delete the Do & Due app and rebuild before rewriting persistence code.
* First `+` sheet presentation and first keyboard startup can be slower in debug builds on device; subsequent opens are usually faster.
* Console text-input messages during quick sheet cancelation appear to be keyboard/debug-session noise unless the app hangs, crashes, or the keyboard consistently fails.

Validated recently:

* Live Xcode diagnostics clean after each pass.
* Full Xcode builds succeeded after recurrence, editor, list, and device-feedback corrections.
* Snippet checks passed for recurring date calculations, including multiple weekdays and old single-weekday compatibility.
* Manual MVP validation is complete: recurrence, notifications, task operations, and persistence are good enough to leave the MVP stage.
* Product name changed from the original name to `Do & Due` for user-facing copy and roadmap language.
* Color palette is now defined in shared style tokens: accent `#4F7B6E`, accent light `#EAF2F0`, overdue `#B85450`, overdue light `#FDF3F2`, text grays, surfaces, border, and separator.

Current focus:

* Continue mockup-aligned visual polish across Editor, Today, Tasks, and Detail.
* Preserve the simple native iOS feel where it improves reliability and accessibility.
* Start the Home Screen widget after the core screens feel final enough.

---

# 42. Current Styling Pass

Completed:

* Compacted old progress notes into the current implementation snapshot to reduce roadmap bloat.
* Updated `TaskEditorView` to share the app background and accent tint from `DoAndDueStyle`.
* Converted the recurrence preview from plain text into a highlighted schedule summary row.
* Tightened weekly weekday controls with selected/unselected fills and borders.
* Tuned completion feedback in task rows: slower checkmark/strikethrough, short status text, light haptic feedback, and springy list repositioning.
* Made fixed scheduled recurrence more discoverable with `Every day`, `Weekdays`, and `Weekends` presets plus custom weekday buttons.
* Updated notification scheduling to avoid capturing SwiftData task objects in notification callbacks and to use reminder-specific notification copy.
* Updated task detail styling with an accent recurrence chip, emphasized next due date, grouped background, and cleaner history rows.
* Started the post-MVP final-product polish phase.
* Updated `TaskEditorView` repeat copy to use clearer creation language: `No repeat`, `After I complete it`, and `On a schedule`.
* Replaced the relaxed recurrence stepper row with a compact minus/value/plus control and menu-style unit picker.
* Added shared style tokens for app surfaces, controls, and separators in `DoAndDueStyle`.
* Changed one-off task copy to `No repeat` to avoid confusing repeat-section language.
* Refined task row metadata so recurrence stays neutral while due/overdue status carries the stronger visual emphasis.
* Applied the Do & Due palette across shared styles, editor controls, task rows, overdue backgrounds, and accent highlight fills.
* Polished Today and Tasks rows with a custom completion circle, branded add button background, palette-correct text, consistent row insets, and softer separators.
* Changed the Today section header from `Due today` to `Today` to better match the mockups and core product language.
* Added notification digest batching to the roadmap: tasks that remind at the same moment should produce one useful summary notification instead of several separate alerts.
* Polished `TaskDetailView` with palette-correct text, cleaner section insets, softer separators, and quieter history checkmark rows.
* Continued `TaskEditorView` polish with palette-correct form rows, separators, repeat controls, and selection text.
* Renamed source-level app/style types and files to `DoAndDueApp.swift`, `DoAndDueApp`, `DoAndDueStyle.swift`, and `DoAndDueStyle`.
* Added `SplashView` as a short branded loading screen before the main tabs.
* Removed unused SwiftUI template files `ContentView.swift` and `Item.swift`.

Validated:

* Live diagnostics clean for the changed files.
* Full Xcode build succeeded.

---

# 43. Current Implementation Snapshot — August 16, 2026

The MVP is functionally complete enough to move toward post-MVP feature work, with one stabilization caveat: automated tests still need a real unit-test target in Xcode.

Completed since the previous snapshot:

* Added `Anytime` scheduling for tasks that should remain visible without becoming overdue.
* Preserved normal recurrence behavior for Anytime recurring tasks: completing one schedules the next due date.
* Updated Today to include `Overdue`, `Today`, `Anytime`, and `Upcoming`.
* Converted Today and Tasks into grouped card-style sections matching the newer light/dark mockups more closely.
* Updated Task Editor and Task Detail to use grouped cards, cleaner section spacing, and mockup-aligned headers.
* Kept `First due` as a visibly editable compact date picker instead of mockup-static text because discoverability is better.
* Removed redundant row metadata in Today and Anytime sections: rows no longer repeat `Due today` or `Anytime` when the section title already supplies that context.
* Kept dates/status visible in mixed sections such as Upcoming, Overdue, and All Tasks.
* Replaced custom-list edit-mode reliance on SwiftUI `editMode` with explicit local edit state in All Tasks.

Current validation state:

* Full Xcode builds are passing.
* Live diagnostics are clean on recently touched Swift files.
* Light and dark previews have been rendered for the core screens during polish.
* Manual app testing has passed for the main MVP flows according to recent device/simulator checks.

Testing status:

* The active Xcode scheme currently reports `0 tests`.
* There is no existing unit-test target in the project.
* A focused Swift Testing file has been drafted at `DoAndDueTests/RecurrenceTests.swift`, covering recurrence edge cases and Anytime recurring completion behavior.
* That file is not active until a Unit Testing Bundle target is added in Xcode and the file is added to that target.
* Equivalent executable checks passed through Xcode's snippet runner for relaxed recurrence, fixed weekly recurrence, monthly 31st handling, February 29 yearly handling, and Anytime recurring completion.

Before starting widgets, the preferred stabilization pass is:

1. Add a `DoAndDueTests` Unit Testing Bundle target in Xcode.
2. Add `DoAndDueTests/RecurrenceTests.swift` to that target.
3. Run the recurrence tests.
4. Do one final manual notification pass: create, edit due date/reminder, complete recurring task, delete task.

After that, start the first post-MVP feature:

> **Home Screen widget**

Reason: it directly supports the product promise of seeing what needs doing without opening the app.

---

# 44. Widget Implementation Completed — August 16, 2026

The first WidgetKit target is now implemented and QA'd.

Current widget behavior:

* The app writes a lightweight JSON snapshot of active tasks into the shared App Group container.
* The widget reads that snapshot instead of opening the SwiftData store directly.
* Small widget: shows the actionable task count and the top urgent task.
* Medium widget: shows a fixed, prioritized list ordered `Overdue`, `Today`, then `Anytime`, with a `+N more` summary when needed.
* Lock Screen rectangular widget: shows a compact count plus the top task.
* Widget rows deep-link into the app: `doanddue://today`, `doanddue://tasks`, and `doanddue://task/<id>` are handled by `RootView`.
* Medium widget rows split the interaction surface: tapping the completion circle queues completion, while tapping the task text opens that task.
* Widget completion uses an App Group command file and `AppIntent`; the app drains queued completions on launch/foreground and applies real task completion through `TaskStore.complete`.
* The widget completion circle was enlarged for easier targeting.

Important WidgetKit constraint:

* Home Screen widgets are not scrollable list surfaces. They should remain glanceable snapshots.
* Medium widgets should continue showing a fixed number of rows plus a `+N more` summary when there are additional tasks.

QA completed:

* Widget displays the expected task snapshot.
* Widget row text opens the correct task.
* Widget completion works from the circle and is reconciled by the app.

Remaining widget ideas:

* Decide whether to add a large widget that includes Upcoming tasks, or keep widgets focused on actionable work only.

---

# 45. Notification Digest Batching — August 16, 2026

Notification batching is now implemented.

Current notification behavior:

* Do & Due still schedules reminders from each task's due date and reminder setting.
* Pending Do & Due notifications are rewritten through `NotificationManager` whenever a task notification is scheduled or canceled.
* Reminders that land on the same date and minute are grouped into one notification.
* Single-task reminders keep their task title and reminder body.
* Multi-task reminders use a digest title such as `3 tasks need attention` and list the first tasks in the body.
* Existing older single-task notification requests can be migrated into the batched format when the scheduler next rewrites pending Do & Due notifications.

Next validation pass:

* Manually create several tasks due at the same reminder time and confirm they produce one pending notification.
* Edit one task's reminder or due date and confirm the digest splits or regroups correctly.
* Delete or complete one task from a digest and confirm the remaining pending notification still contains the other tasks.

---

# 46. Done Archive — August 16, 2026

A lightweight Done tab is now implemented.

Current behavior:

* The app has a third tab: `Done`.
* `DoneView` lists task completions newest first using the existing `TaskCompletion` records.
* Rows show the completed task title, completion date, and recurrence summary when available.
* Tapping a completion opens the underlying task detail sheet when the task still exists.
* Completed one-off tasks are no longer invisible to the user; their completion record appears in Done.
* Recurring task completions also appear, so users can audit maintenance/history over time.

Intentional limits for now:

* Done is read-only.
* There is no restore/undo-completion behavior yet.
* The view is a simple recent-completions archive rather than a full analytics/history system.

---

# 47. App Store Release Requirements

This section tracks what Do & Due needs before a first App Store submission. It is based on Apple's current App Review Guidelines and App Store Connect submission requirements.

## Product and binary readiness

* [ ] Choose final bundle identifier, app display name, SKU, version, and build number before upload.
* [ ] Verify the app target and widget extension both build in Release configuration.
* [ ] Verify all app capabilities are intentional: App Groups for the widget and User Notifications for reminders.
* [ ] Confirm the widget extension is useful but not required for the core app to function.
* [ ] Remove, hide, or keep `#if DEBUG`-only development tools out of Release builds, including the pending-reminders debug inspector.
* [ ] Test a clean install with no existing SwiftData store.
* [ ] Test upgrade behavior from the current development data model before submitting an update after first release.
* [ ] Run the unit-test target and complete a final manual QA pass on create, edit, complete, delete, recurrence, notifications, widget display, widget deep links, and widget completion.
* [ ] Archive the app in Xcode, validate the archive, and upload through Xcode Organizer or App Store Connect tooling.

## App Review guideline readiness

* [ ] The app must be complete and not presented as a beta, demo, or trial build.
* [ ] All visible functionality must be documented enough for App Review to understand it.
* [ ] App Review notes should specifically mention: local-only task storage, local notifications, Home Screen/Lock Screen widget, App Group snapshot sharing, and widget completion queue reconciliation on app launch/foreground.
* [ ] The app must not include hidden production features. Debug-only features should compile out of Release builds.
* [ ] The app should not require an account or demo credentials. If that changes later, provide a non-expiring demo account in App Review information.
* [ ] The app should avoid misleading claims. Store copy should describe personal task reminders and recurring maintenance, not project management, medical advice, or financial compliance.
* [ ] Confirm all icons, screenshots, mockups, and product copy are owned by us or cleared for App Store use.
* [ ] Confirm local notifications are optional and clearly tied to user-created reminders.

## App Store Connect metadata

* [ ] App name: `Do & Due` or final approved variant, maximum 30 characters.
* [ ] Subtitle: concise 30-character summary.
* [ ] Primary category: likely `Productivity`.
* [ ] Secondary category: optional; consider `Utilities` if useful.
* [ ] Age rating questionnaire completed. Expected result should be low age rating because the app has no user-generated public content, web access, purchases, gambling, medical treatment, or mature content.
* [x] Support URL created and publicly accessible: `https://glennonr.github.io/DoAndDue/support/`
* [ ] Marketing URL optional.
* [x] Privacy Policy URL created and publicly accessible: `https://glennonr.github.io/DoAndDue/privacy/`
* [ ] Copyright holder and contact information entered.
* [ ] Keywords written around recurring tasks, reminders, maintenance, chores, due dates, checklist, and home upkeep.
* [ ] Description and promotional text accurately describe the app's current features.
* [ ] Review notes written with enough detail to test notifications and widgets.
* [ ] Screenshots uploaded for required iPhone display sizes; include Today, editor, task detail, Done, and widget where possible.
* [ ] App preview video optional; skip unless we can make it polished.

## Privacy and data disclosure

* [x] Publish a privacy policy before submission: `https://glennonr.github.io/DoAndDue/privacy/`
* [ ] Complete App Privacy answers in App Store Connect.
* [ ] Current expected privacy posture: no account, no analytics SDK, no ads, no tracking, no third-party data sharing, and task data stored locally on-device.
* [ ] Confirm whether local notification content, widget snapshots, and SwiftData storage count only as on-device user content and are not collected by the developer.
* [ ] If any analytics, crash reporting, cloud sync, support form, email capture, or third-party SDK is added later, update the privacy policy and App Privacy answers before submission.
* [ ] Confirm no App Tracking Transparency prompt is needed unless tracking or IDFA access is introduced later.

## App assets and launch polish

* [ ] Final app icon added at all required sizes through the asset catalog.
* [ ] Widget icon/extension appearance checked in light mode, dark mode, tinted mode, and Lock Screen contexts.
* [ ] Launch screen reviewed for brand consistency.
* [ ] Light and dark mode screenshots verified against the final UI.
* [ ] Dynamic Type sanity pass for Today, Tasks, Done, editor, detail, and widget.
* [ ] VoiceOver labels checked for completion buttons, add buttons, delete buttons, widget controls, and debug-free Release UI.

## Legal and policy checks

* [ ] Decide whether the standard Apple EULA is sufficient. It should be sufficient unless we add custom terms.
* [ ] Export compliance answered in App Store Connect. Expected answer should be straightforward if the app only uses standard Apple platform encryption and no custom cryptography.
* [ ] No in-app purchases, subscriptions, ads, external payments, donations, or account deletion requirements apply in the current product.
* [ ] If cloud sync/accounts are added later, add account deletion and data export/deletion handling before submission.

## First submission recommendation

Submit only after the app has passed:

1. Clean install QA.
2. Notification scheduling and digest QA.
3. Widget display, deep-link, and completion QA.
4. Done archive QA.
5. Release archive validation.
6. App Store Connect metadata and privacy review.
