---
description: "Fill the Jira time tracker from your own GitLab work — 08:00–16:00 on every working day"
---

Log work for the period named after `/log-work`: `--from <YYYY-MM-DD>`, optional
`--to <YYYY-MM-DD>`, optional `--holidays <date|date..date>,…`. No `--from` → ask for it. `--to`
defaults to today.

Load `jira-tickets` — it owns the Jira tool chain. The user waived its approval gate for this
command. This command owns the calendar, the detection, and the split. Worklogs only: no other
Jira field, no GitLab writes.

## Calendar

A working day is Monday–Friday in the period, minus every `--holidays` date or inclusive range.
Weekends and holidays are never written to, even when they carry activity. Each working day is
covered 08:00–16:00 local time, 8h, nothing outside it.

## Detection

1. **Own work** — `list_events` on the `gitlab` server, `after` the day before `--from`,
   `before` the day after `--to`, every page, projected with `jmespath` to date, action,
   `push_data.ref`, `push_data.commit_title` and `target_title`. Only what the user made counts:
   pushes with a commit, and merge requests they opened or merged. Approvals and comments on
   others' merge requests, branch deletions, and pushes without a commit get no time. Bucket by
   local date.
2. **Work items** — group a day's work by branch or merge request, and name each item in a few
   words from its commit and merge request titles ("Kafka on meta-worker", "Connector chart and
   deploy MVP").
3. **Ticket per item** — a `[A-Z][A-Z0-9]+-[0-9]+` key in the item's branch, commit or merge
   request title is its ticket. A keyless item goes to the ticket it serves, chosen from the keys
   of the user's own work in the period and `assignee = currentUser() AND updated >= <--from>`,
   matched on repository and subject: chart, deploy and monitoring work goes to the feature it
   ships, release and version bumps in deploy repositories to the sprint release ticket. No
   convincing match → drop the item; its hours spread over the day's ticketed items. Confirm all
   keys in one `key in (…)` search.
4. **Empty days** — a working day without a ticketed item continues the previous working day's
   main item, or the next one's at the start of the period. No ticket anywhere → report and stop.

## Split

1. **Existing time** — `jira_get_user_worklogs` for the period. Time already logged on a day is
   kept and subtracted from that day's 8h; a full day is skipped. Never edit or delete an
   existing worklog.
2. **Remainder** — items on the same ticket merge into one entry. Share the day's remaining
   hours by each entry's weight (commits pushed, span from first to last event) in whole hours,
   at most three entries a day, the largest first. Entries run back to back from 08:00, skipping
   the slots existing worklogs occupy.

## Then

Every entry carries a ticket. Write each entry with `jira_add_worklog`, the item names as its
comment, without asking. Then report one table — date, key, summary, start, duration, comment —
with carry-over days marked, plus the skipped holidays, the dropped items, the totals per key,
and any entry that failed with its error.
