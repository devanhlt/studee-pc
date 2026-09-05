#!/usr/bin/env bash
# Resolve OCR worker venv (dev: ./.venv, packaged: Application Support).
# shellcheck shell=bash
ocr_worker_venv_dir() {
  local root="$1"
  local support="${HOME}/Library/Application Support/com.studee.studeePc/ocr_runtime/.venv"
  if [[ -x "$support/bin/python" || -L "$support/bin/python" ]]; then
    printf '%s\n' "$support"
    return 0
  fi
  if [[ -x "$root/.venv/bin/python" || -L "$root/.venv/bin/python" ]]; then
    printf '%s\n' "$root/.venv"
    return 0
  fi
  # Packaged app default target (may not exist yet — setup will create it).
  if [[ "$root" == *".app/Contents/Resources/ocr_worker"* ]]; then
    mkdir -p "$(dirname "$support")"
    printf '%s\n' "$support"
    return 0
  fi
  printf '%s\n' "$root/.venv"
}
