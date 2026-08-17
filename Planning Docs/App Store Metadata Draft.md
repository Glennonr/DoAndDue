# Do & Due App Store Metadata Draft

_Last updated: August 16, 2026_

This is working copy for App Store Connect. Review before submission.

## App Name

Do & Due

## Subtitle Options

App Store subtitles are limited to 30 characters.

* Recurring task reminders
* Remember what is due
* Tasks, due dates, repeats

Recommended: `Recurring task reminders`

## Primary Category

Productivity

## Secondary Category

Utilities, optional.

## Promotional Text

Keep track of what needs doing now, later, and again after you finish it.

## Short Description Direction

Do & Due is a simple task app for recurring personal reminders, home maintenance, chores, bills, and anything else that needs to happen on a due date or after you complete it.

## Full Description Draft

Do & Due helps you remember what needs doing and when it needs to happen again.

It is built for everyday tasks that do not fit neatly into a standard checklist: replacing filters, renewing registrations, paying bills, cleaning vents, scheduling appointments, checking supplies, and other recurring responsibilities.

Create one-time tasks, tasks that repeat after you complete them, or tasks that follow a fixed calendar schedule. Use Anytime tasks for things that should stay visible without becoming overdue.

Key features:

* Today view for overdue, due today, anytime, and upcoming tasks
* One-time, after-completion, and fixed-schedule repeats
* Local reminders with notification digest batching
* Home Screen and Lock Screen widgets
* Complete tasks from the widget
* Done history for recent completions
* Local on-device storage with no account required

Do & Due is intentionally small, focused, and low-friction. Open it, see what needs your attention, and move on.

## Keywords Draft

App Store keyword field is limited and comma-separated. Do not include the app name if the name already covers it.

recurring tasks,reminders,chores,maintenance,due dates,checklist,home,bills,repeat,todo

Need final compression before submission.

## What's New For 1.0

Initial release.

## Support URL Requirements

Create a simple public support page with:

* Contact email
* Brief app description
* Basic troubleshooting for notifications and widgets
* Privacy policy link

Draft source: `docs/support.md`

Expected GitHub Pages URL after Pages is enabled from the `docs/` folder:

`https://glennonr.github.io/DoAndDue/support/`

## Privacy Policy URL

Draft source: `docs/privacy.md`

Expected GitHub Pages URL after Pages is enabled from the `docs/` folder:

`https://glennonr.github.io/DoAndDue/privacy/`

## Review Notes Draft

Do & Due is a local-first recurring task/reminder app. No account or demo credentials are required.

Features to review:

* Create a task from the Today or Tasks tab using the plus button.
* Choose one-time, after-completion, or fixed-schedule recurrence in the editor.
* Choose a reminder to schedule a local notification.
* Add the Home Screen widget to view current tasks.
* In the medium widget, tap the task text to open that task in the app.
* In the medium widget, tap the completion circle to queue completion. The app applies queued widget completions on launch or when returning to foreground.
* The Done tab shows completion history.

Implementation notes:

* Task data is stored locally using Apple's system storage frameworks.
* The widget reads a lightweight JSON snapshot from the shared App Group container.
* Widget completion uses an App Group command file and is reconciled by the app.
* Local notifications are scheduled only for user-created reminders.

No login, purchases, subscriptions, ads, analytics, tracking, or server-side user data collection are included in the current build.

## Screenshot Set Draft

Recommended first screenshot set:

1. Today view with overdue/today/anytime sections.
2. Task editor showing repeat options.
3. Task detail showing next due and history.
4. Done tab showing completion history.
5. Widget on Home Screen.

## Privacy Summary For App Store Connect

Expected current answer: Do & Due does not collect data from this app.

Rationale:

* Task data is stored locally on device.
* Widget snapshots stay in the local App Group container.
* Local notification content is scheduled on device.
* No analytics, ads, tracking, accounts, cloud sync, crash SDK, or third-party data transmission is currently present.

Re-check this if any SDK or cloud feature is added.
