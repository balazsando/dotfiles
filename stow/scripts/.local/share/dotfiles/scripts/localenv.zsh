#!/usr/bin/env zsh
_get_secrets() {
  local base=${VAULT_ADDR%/}/v1 mount=${1%%/*} spath=${1#*/}/$4 user=$2 token keys k p
  token=$(P=$3 jq -n '{password: env.P}' | curl -fsS -d @- "$base/auth/userpass/login/$user" | jq -er '.auth.client_token') || return
  _get() { curl -fsS -H "X-Vault-Token: $token" "$base/$1"; }
  _get auth/token/lookup-self >/dev/null || return
  keys=$(_get "$mount/metadata/$spath?list=true" 2>/dev/null | jq -r '.data.keys[] | select(endswith("/") | not)')
  for k in ${=keys:-.}; do
    p=$spath; [[ $k == . ]] || p=$spath/$k
    _get "$mount/data/$p" | jq -c '.data.data | with_entries(select(.key | test("^[A-Za-z_][A-Za-z0-9_]*$")) | .value |= tostring)' || return
  done
}

[[ $1 == -e && $2 == (test|preprod) ]] || { echo 'usage: localenv -e test|preprod' >&2; exit 2; }
for v in VAULT_ADDR VAULT_PATH VAULT_USER VAULT_PASS VAULT_PATH_CONNECTOR VAULT_USER_CONNECTOR VAULT_PASS_CONNECTOR; do
  [[ -n ${(P)v} ]] || { echo "localenv: $v is not set" >&2; exit 1; }
done
app=$(_get_secrets "$VAULT_PATH" "$VAULT_USER" "$VAULT_PASS" "$2") || { echo 'localenv: app fetch failed' >&2; exit 1; }
conn=$(_get_secrets "$VAULT_PATH_CONNECTOR" "$VAULT_USER_CONNECTOR" "$VAULT_PASS_CONNECTOR" "$2") || { echo 'localenv: connector fetch failed' >&2; exit 1; }
all=$(print -r -- "$app"$'\n'"$conn" | jq -s 'add // {}') || exit 1
(umask 077; jq -r 'to_entries[] | "\(.key)=\(.value)"' <<<"$all" >| .env.local && chmod 600 .env.local) || { echo 'localenv: cannot write .env.local' >&2; exit 1; }
git check-ignore -q .env.local 2>/dev/null || [[ $? == 128 ]] || echo "localenv: $PWD/.env.local is not git-ignored" >&2
jq -r 'to_entries[] | "export \(.key)=\(.value | @sh)"' <<<"$all"
