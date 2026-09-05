#!/usr/bin/env bash
# addcerts — Import ~/certs/*.crt into the Java truststore via keytool.
# Called by install.sh (bash) and sourced by .zshrc for interactive use.
# Confirms each cert (it becomes trusted by every Java process). --yes to skip.

addcerts() {
  local assume_yes=0
  [[ "${1:-}" == "--yes" || "${ADDCERTS_ASSUME_YES:-0}" == "1" ]] && assume_yes=1

  local cert_dir="$HOME/certs"
  [[ -d "$cert_dir" ]] || { echo "  ⊘ ~/certs not found — skipping"; return; }

  local java_bin
  java_bin="$(mise which java 2>/dev/null || command -v java 2>/dev/null || true)"
  [[ -n "$java_bin" ]] || { echo "  ⊘ java not found — skipping"; return; }

  local java_home keytool keystore
  java_home="$(dirname "$(dirname "$(readlink -f "$java_bin")")")"
  keytool="$java_home/bin/keytool"
  keystore="$java_home/lib/security/cacerts"
  [[ -x "$keytool" ]] || { echo "  ⊘ keytool not found — skipping"; return; }

  if (( ! assume_yes )) && [[ ! -t 0 ]]; then
    echo "  ⊘ addcerts needs a terminal to confirm — re-run with --yes to import unattended"
    return
  fi

  local imported=0 skipped=0 failed=0
  local cert alias_name subject fingerprint reply out
  for cert in "$cert_dir"/*.crt; do
    [[ -f "$cert" ]] || continue
    alias_name="$(basename "$cert" .crt)"

    subject="$("$keytool" -printcert -file "$cert" 2>/dev/null \
      | sed -n 's/^Owner: //p' | head -1)"
    fingerprint="$("$keytool" -printcert -file "$cert" 2>/dev/null \
      | sed -n 's/^[[:space:]]*SHA256: //p' | head -1)"

    if [[ -z "$subject" ]]; then
      echo "  ✗ $alias_name — not a readable certificate, skipping"
      failed=$((failed + 1))
      continue
    fi

    echo ""
    echo "  Certificate: $alias_name"
    echo "    Subject:     ${subject:-<unknown>}"
    echo "    SHA256:      ${fingerprint:-<unknown>}"

    if (( ! assume_yes )); then
      read -rp "    Trust this for ALL Java processes? [y/N] " reply
      if [[ "${reply,,}" != "y" ]]; then
        echo "    ⊘ skipped"
        skipped=$((skipped + 1))
        continue
      fi
    fi

    if out=$(sudo "$keytool" -importcert -noprompt -trustcacerts \
      -alias "$alias_name" \
      -file "$cert" \
      -keystore "$keystore" \
      -storepass changeit 2>&1); then
      echo "    ✔ imported"
      imported=$((imported + 1))
    elif grep -qi 'already exists' <<<"$out"; then
      echo "    ⊘ already present"
      skipped=$((skipped + 1))
    else
      echo "    ✗ import failed: $(head -1 <<<"$out")"
      failed=$((failed + 1))
    fi
  done

  echo ""
  echo "  ✔ Java truststore: $imported imported, $skipped skipped, $failed failed"
  (( failed == 0 ))
}

addcerts "$@"
