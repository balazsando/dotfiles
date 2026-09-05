# Grafana HTTP API: Entry Points and Safe Patterns

This reference is a pragmatic "how to call the API" guide (authentication, example requests, and where to look next), with pointers to the official Grafana HTTP API documentation.

---

## Authentication (most common)

When calling Grafana from scripts/automation, use an API token and send it as:

```bash
Authorization: Bearer <GRAFANA_API_TOKEN>
Content-Type: application/json
```

Grafana's HTTP API docs are the source of truth for auth schemes and endpoints:
- Dashboard API: https://grafana.com/docs/grafana/latest/developer-resources/api-reference/http-api/dashboard/

---

## Create or update a dashboard

Endpoint:

- `POST /api/dashboards/db`

Curl example (create or update):

```bash
curl -sS \
  -X POST "https://<grafana-host>/api/dashboards/db" \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -H "Content-Type: application/json" \
  -d @dashboard.json
```

Minimal request shape (the full dashboard JSON goes into `dashboard`):

```json
{
  "dashboard": {
    "id": null,
    "uid": "my-dashboard-uid",
    "title": "Production Overview",
    "schemaVersion": 16,
    "timezone": "browser",
    "panels": []
  },
  "folderUid": "my-folder-uid",
  "message": "Updated via automation",
  "overwrite": true
}
```

Notes:

- Use `overwrite: true` when you want Grafana to replace an existing dashboard with the same `uid`.
- If you get `version-mismatch`, the API expects a specific dashboard version; set the correct `dashboard.version` (or use `overwrite` when appropriate).

---

## Provision alert rules (HTTP provisioning API)

Unified alerting rule definitions are typically managed via the provisioning HTTP API.

Example base endpoints (see official "Alerting provisioning HTTP API" docs for full details):

- `GET /api/v1/provisioning/alert-rules`
- `POST /api/v1/provisioning/alert-rules`
- `PUT /api/v1/provisioning/alert-rules/:uid`
- `DELETE /api/v1/provisioning/alert-rules/:uid`

Docs entry point:
https://grafana.com/docs/grafana/latest/developer-resources/api-reference/http-api/api-legacy/alerting_provisioning/

---

## Query current managed alert instances (state)

If you need the current active/silenced/inhibited alert instances (managed alert state), Grafana exposes an Alertmanager-compatible endpoint.

Example endpoint:
- `GET /api/alertmanager/grafana/api/v2/alerts`

Use this when you need "what is currently firing" rather than "what alert rules are provisioned".

