# Unified Alerting (Workflow + Failure Modes)

This reference focuses on Grafana's unified alerting workflow (rule groups, evaluations, and routing), and the most common reasons alerting "doesn't work".

---

## Mental model

- An alert rule lives inside a rule group.
- The group has an evaluation interval.
- Each evaluation runs the rule's query/expression pipeline.
- When the rule condition matches, Grafana updates alert state and emits notifications according to labels/receivers and notification policies.

---

## What to verify first (when alerts don't fire)

1. **Rule group evaluation interval**  
   Make sure the evaluation interval is frequent enough for how quickly the metric/log signal changes.

2. **Query / expression correctness**  
   Confirm the query returns the shape Grafana expects (a numeric result for conditions, and any expected label set).

3. **Threshold condition and `for` duration**  
   - Threshold must match what you see in Explore.
   - If `for` is configured, the condition must remain true continuously for that duration.

4. **No-data / error handling**  
Unified alerting can treat "no data" and "execution error" in different ways. Verify how you want those states handled.

5. **Labels, routing, and notification policy**  
   Notifications depend on matching labels to the routing policy and contact point.

6. **Time range and query window**  
Alert queries typically evaluate over a fixed window; if it doesn't include enough historical context, you'll see flapping or missing alerts.

---

## Debug workflow to use in answers

When the user reports an alert issue, ask for:

- Grafana version and whether they're using unified alerting
- The rule (or rule group) definition details: query/expression, condition, `for`, and labels/annotations
- What they expected to happen vs what actually happened

Then guide them through:

1. Reproduce in Explore (same datasource, same time window, same query)
2. Validate that the condition is met (including `for`)
3. Check label sets used for routing
4. Confirm notification policy + contact point mapping
5. Check alert execution logs / rule execution status in Grafana

