#!/usr/bin/env bash
# node-ca.sh — source this to get node_ca_setup()
#
# Node ignores the OS trust store, so corporate CAs must be passed explicitly.
# Builds a bundle from ~/certs and exports NODE_EXTRA_CA_CERTS. Returns 1 if no
# certs are available. Bundle lives in a private dir — whoever can write it
# controls what node trusts.

node_ca_setup() {
  local certs_dir="${HOME}/certs"
  [ -d "$certs_dir" ] || return 1

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
  mkdir -p "$cache_dir" || return 1
  chmod 700 "$cache_dir" 2>/dev/null

  local bundle="$cache_dir/ca-bundle.pem"
  ( umask 077; cat "$certs_dir"/*.crt >"$bundle" 2>/dev/null ) || true
  [ -s "$bundle" ] || return 1

  export NODE_EXTRA_CA_CERTS="$bundle"
  return 0
}
