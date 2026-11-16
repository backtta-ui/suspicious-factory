#!/bin/sh
set -eu
# Render terminates TLS at its edge. Only the proxy port is public.
PORT=10001 /usr/local/bin/godot --headless --path /app --script res://scripts/seal/server.gd &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null || true' EXIT INT TERM
python3 /app/server/health_proxy.py &
PROXY_PID=$!
wait "$SERVER_PID"
kill "$PROXY_PID" 2>/dev/null || true
