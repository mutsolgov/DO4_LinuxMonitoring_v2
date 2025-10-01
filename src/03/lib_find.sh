#!/usr/bin/env bash

# lib_find.sh - функции поиска для cleanup
# Возвращает списки в null-terminated потоках (безопасно для пробелов).

# parse_log <logpath> -> печатает сначала список файлов (null-terminated), потом строка SEP, потом список директорий (null-terminated)
parse_log() {
    local logpath="$1"
    local tmpf
    # Читаем лог (ожидаем формат TYPE|PATH|DATE|SIZE)
    # Запишем файлы в tmp_files, каталоги в tmp_dirs
    local tmp_files tmp_dirs
    tmp_files=$(mktemp) || return 1
    tmp_dirs=$(mktemp) || return 1

    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        # разделяем строку по |
        IFS='|' read -r typ path rest <<< "$line"
        # убираем ведущие/замыкающие пробелы
        path="$(echo "$path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [ -z "$path" ] && continue
        if [ "$typ" = "FILE" ]; then
            printf '%s\0' "$path" >> "$tmp_files"
        elif [ "$typ" = "DIR" ]; then
            printf '%s\0' "$path" >> "$tmp_dirs"
        fi
    done < "$logpath"

    # выведем файлы, разделитьль и директории
    cat "$tmp_files"
    printf '\0'   # пустой нулевой элемент как разделитель
    # сортируем директории по длине пути по убыванию (чтобы удалять вложенные сначала)
    python3 - <<PY 2>/dev/null || {
        # если python не доступен -используем простой reverse
        cat "$tmp_dirs"
        rm -f "$tmp_files" "$tmp_dirs"
        return 0
    }
import sys
data = sys.stdin.buffer.read().split(b'\0')
dirs = [d.decode() for d in data if d]
dirs.sort(key=lambda s: -len(s))
sys.stdout.write('\0'.join(dirs).encode().decode() + '\0')
PY < "tmp_dirs"

