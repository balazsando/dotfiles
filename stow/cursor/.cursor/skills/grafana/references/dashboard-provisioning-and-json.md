# Dashboard JSON and Provisioning Workflows

This reference helps with two closely related topics:

1. Editing or generating a Grafana dashboard definition (dashboard JSON).
2. Provisioning dashboards automatically using Grafana's filesystem provisioning (YAML + JSON).

---

## Dashboard JSON: what to look for

Common top-level concepts you'll see in exported dashboard JSON:

- `title`: human-friendly name
- `uid`: stable identifier used by Grafana for updates
- `schemaVersion`: dashboard schema version
- `time` / `timepicker`: default time range and picker config
- `timezone`: timezone handling (`browser`, `utc`, etc.)
- `templating` / `variables`: dashboard variables
- `panels`: the actual visualizations (each panel has targets/expressions)
- `annotations`: event overlays (if configured)
- `refresh`: dashboard refresh interval (if configured)

When debugging "variable doesn't work" or "panel doesn't update", verify:

- variable `name` and `type` (query/constant/custom)
- variable `query` and how it feeds panel queries
- panel `targets` / expressions referencing the right variable(s)

---

## Provisioning dashboards: YAML provider + dashboard files

Grafana provisions dashboards via YAML configuration files placed under the provisioning dashboards directory.
In that YAML, you configure one or more *providers* that point to where dashboard JSON files live on disk.

Key fields you'll typically see:

- `apiVersion: 1`
- `providers:`
- `name`: unique provider name
- `orgId`: organization id (often `1`)
- `folder` / `folderUid`: where dashboards appear in the UI
- `type: file`
- `updateIntervalSeconds`: how often Grafana scans for changes
- `allowUiUpdates`: whether UI edits are allowed to persist for provisioned dashboards
- `options.path`: filesystem path containing dashboard JSON files
- `options.foldersFromFilesStructure: true`: mirror directory structure as folders

Example provider shape:

```yaml
apiVersion: 1

providers:
  - name: dashboards
    orgId: 1
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: false
    options:
      path: /etc/dashboards
      foldersFromFilesStructure: true
```

When using `foldersFromFilesStructure`, ensure you follow the provisioning rules:

- folder/folderUid are managed via the filesystem structure (so you typically leave the UI folder options unset for that provider).

---

## Recommended "safe update" checklist

When you update dashboards via JSON export + provisioning:

- Preserve `uid` (Grafana uses it to identify the dashboard across updates).
- Keep dashboard JSON consistent with your Grafana version's schema (mismatches can cause ignored fields).
- If using provisioning + templates, validate variable wiring after importing (exported dashboards can reference variables differently depending on how they were built).
- Prefer stable identifiers (`uid`) over only relying on `title`.

