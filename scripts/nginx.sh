#!/usr/bin/env bash
#
# nginx.sh — Start nginx alone in the foreground with the local dev config.
#
# Mirrors how scripts/serve.sh launches nginx (same prefix, config, and
# pre-created directories) — keep the two in sync.
#
# Usage: make nginx  (or ./scripts/nginx.sh from anywhere)

set -e

REPO_ROOT="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd -P)"
# Hermes agent terminal: MSYS->Windows path auto-conversion is disabled, so
# native Windows tools (nginx) misresolve POSIX-style /c/... roots.
if command -v cygpath >/dev/null 2>&1 && [[ "$REPO_ROOT" == /* ]]; then
    REPO_ROOT="$(cygpath -w "$REPO_ROOT")"
fi
cd "$REPO_ROOT"

mkdir -p logs
mkdir -p temp/client_body_temp temp/proxy_temp temp/fastcgi_temp temp/uwsgi_temp temp/scgi_temp

NGINX_CONF="$(bash "$REPO_ROOT/scripts/nginx-local-conf.sh")"
exec nginx -g 'daemon off;' -c "$NGINX_CONF" -p "$REPO_ROOT"
