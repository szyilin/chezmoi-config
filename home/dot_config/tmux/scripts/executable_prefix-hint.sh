#!/usr/bin/env sh

client_name="$1"
hint_delay_ms="${2:-1200}"
hint_duration_ms="${3:-2500}"
hint_message="${4:-提示: 按 ? 查看快捷键帮助}"

if [ -z "$client_name" ]; then
  exit 0
fi

sleep_seconds="$(awk "BEGIN { printf \"%.3f\", $hint_delay_ms / 1000 }")"
sleep "$sleep_seconds"

current_table="$(tmux display-message -p -c "$client_name" '#{client_key_table}' 2>/dev/null)"

if [ "$current_table" = "prefix" ]; then
  tmux display-message -c "$client_name" -d "$hint_duration_ms" "$hint_message"
fi
