#!/usr/bin/env bash
# kube-merge.sh — Build ~/.kube/config from ~/.kube/config-*, one unique context per file,
# so k9s (:ctx) and kubectx can switch between them. Re-runnable; the source files are untouched.
# Usage: kube-merge.sh [-n]   (-n: list the contexts, write nothing)

set -euo pipefail
umask 077

dry=false
[[ "${1:-}" == "-n" ]] && dry=true

command -v kubectl >/dev/null || { echo "kube-merge: kubectl not found (mise install)" >&2; exit 1; }
command -v jq >/dev/null      || { echo "kube-merge: jq not found" >&2; exit 1; }

dir="$HOME/.kube"
files=("$dir"/config-*)
[[ -e "${files[0]}" ]] || { echo "kube-merge: no $dir/config-* — run bw-restore.sh first" >&2; exit 1; }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

for f in "${files[@]}"; do
  name="$(basename "$f")"; name="${name#config-}"; name="${name%.*}"
  json="$(KUBECONFIG="$f" kubectl config view --flatten --raw -o json 2>/dev/null)" ||
    { echo "kube-merge: skipping $(basename "$f"): kubectl cannot parse it" >&2; continue; }
  jq --arg p "$name" '
      (.contexts | length) as $n
      | .clusters |= map(.name = "\($p)/\(.name)")
      | .users    |= map(.name = "\($p)/\(.name)")
      | .contexts |= map(.context.cluster = "\($p)/\(.context.cluster)"
                         | .context.user = "\($p)/\(.context.user)"
                         | .name = (if $n == 1 then $p else "\($p)-\(.name)" end))
      | {clusters, users, contexts}' <<<"$json"
done | jq -s '
  {apiVersion: "v1", kind: "Config", preferences: {},
   clusters: (map(.clusters) | add), users: (map(.users) | add), contexts: (map(.contexts) | add),
   "current-context": (map(.contexts[0].name) | first)}' > "$tmp"

jq -r '.contexts[].name' "$tmp"
$dry && exit 0
mv "$tmp" "$dir/config"
echo "kube-merge: wrote $dir/config"
