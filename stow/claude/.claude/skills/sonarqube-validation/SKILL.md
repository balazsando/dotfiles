---
name: sonarqube-validation
description: "All SonarQube work: validating a change after editing code, checking a quality gate, collecting a report for a project or set of files, and the data-collection step of /sonar-fix. Owns all sonarqube MCP access, project matching, report collection, and interpretation."
argument-hint: "[project key or name] [--severity ...] [--new-code] [--path <glob>]"
---

# SonarQube Validation

Single owner of everything that talks to the `sonarqube` MCP server: project matching, report
collection, and how to read the result. Commands, skills, and rules that need Sonar data follow
this file instead of calling the MCP their own way.

## Hard limits

- Read-only. Never call `resolveIssue`, `confirmIssue`, `reopenIssue`, `markIssueFalsePositive`,
  `markIssueWontFix`, `markIssues*`, `assignIssue`, `addCommentToIssue`, or
  `update_hotspot_status` unless the user asked for that exact status change.
- Never present Sonar data as the state of the working tree — it is the last analysis (§4).
- Never invent an issue key, rule key, severity, or gate status. Missing data is "unknown".

## 1. Connect

The tools live on the `sonarqube` MCP server. If a call errors or the server is not registered,
try `system_ping`, then report that validation could not run and what is left unverified — do not
fall back to guessing at code quality, and do not silently skip the check.

## 2. Match the project

Resolve the project key in this order, stopping at the first hit:

1. A key or name given by the caller (command argument, user message)
2. `sonar.projectKey` in `sonar-project.properties`, `pom.xml`, `build.gradle*`, `.gitlab-ci.yml`
3. Maven `groupId:artifactId`
4. The repository slug from `git remote get-url origin`

Confirm the candidate with `projects`, or with `components` (`qualifiers: ["TRK"]`, `query`) when
the project list is long. State the key and name before acting on any finding. Ask when two
projects match or none does — a report from the wrong project is worse than no report.

Branch: pass the analysed branch as `branch` (the repo's default branch, or the feature branch
when Sonar analyses it); use `pull_request` for an MR analysis. An unanalysed branch returns
nothing — fall back to the default branch and say which branch the report describes.

## 3. Collect the report

- **Issues** — `issues` with `project_key`, `branch`, and
  `statuses: ["OPEN", "CONFIRMED", "REOPENED"]`. Scope every call: `components` / `files` /
  `directories` for the touched paths, plus `types`, `severities` or `impact_severities`,
  `rules`, and `in_new_code_period: true` for new code only. Page with `page_size` / `page`;
  take one focused page rather than the whole backlog.
- **Quality gate** — `quality_gate_status` with `project_key` (+ `branch` / `pull_request`).
- **Metrics**, only when trends are asked for — `measures_component` (`component`, `metric_keys`:
  `bugs`, `vulnerabilities`, `code_smells`, `coverage`, `duplicated_lines_density`),
  `measures_history` for movement over time.
- **Context on a finding** — `source_code` for the reported lines, `scm_blame` for authorship.
- **Security hotspots** — `hotspots` / `hotspot`, never `issues`. Review and report only.

Default scope after a change: the files the change touched, all types, all severities.
Default scope for a cleanup run: the project, narrowed by the caller's filters.

## 4. Interpret

- **Stale by design.** Sonar reports the last analysis, not `HEAD`. Re-read the local file at the
  reported `file:line` before acting; drop findings the working tree no longer matches.
- **Unanalysed is unknown, not clean.** No findings for code Sonar has not analysed yet proves
  nothing — say so instead of reporting a pass.
- **Ownership.** Findings the current change introduced belong to the current change. Pre-existing
  findings belong to `/sonar-fix` — list them, do not fix them in passing.
- **Order.** Bugs → vulnerabilities → code smells, highest severity first (`BLOCKER` >
  `CRITICAL` > `MAJOR` > `MINOR` > `INFO`; impacts `HIGH` > `MEDIUM` > `LOW`).
- **Gate.** `ERROR` is a failure — name each failing condition with its actual and required value.
  `OK` holds for the last analysis only. No gate configured is unknown, not a pass.
- Generated, vendored, and `@SuppressWarnings` / `NOSONAR` code is out of scope.

## 5. Report

State, in this order: project key and name; branch; quality gate status with any failing
conditions; findings attributable to the change (rule, severity, `file:line`, one line each);
pre-existing findings as a count plus a pointer to `/sonar-fix`; and anything left unverified —
server unreachable, branch unanalysed, or an analysis older than the change.
