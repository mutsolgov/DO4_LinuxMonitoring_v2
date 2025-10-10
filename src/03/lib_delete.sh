#!/usr/bin/env bash
# lib_delete.sh - удаление файлов/директорий и запись в cleanup.log

CLEANUP_LOG="${CLEANUP_LOG:-./cleanup.log}"

# Запись в лог удаления
log_deleted() {
    local typ="$1" path="$2" when="$3" size="$4" method="$5"
    printf 'DEL|$s|$s|$s|$s|$s\n' "$typ" "$path" "$when" "$size" "$method" >> "$CLEANUP_LOG"
}

#  Выполнеие удалеия: на вход null-terminated список файлов, затем один нулевой разделитель, затем null-trminated список директорий.
do_delete_stream() {
    local method="$1"
    local now
    now="$(date '+%F %T')"

