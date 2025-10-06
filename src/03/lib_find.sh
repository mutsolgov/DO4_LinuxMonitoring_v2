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

    rm -f "$tmp_files" "$tmp_dirs" "$tmpf"
    return 0
}

# find_by_time <basedir> <start> <end> -> печатает files null-terminated, разделитель, dirs null-terminated
find_by_time() {
    local base="$1"; local start="$2"; local end="$3"
    local tf td
    tf=$(mktemp) || return 1
    td=$(mktemp) || return 1

    # используем find -newermt (mtime внутри интервала start <= mtime < end)
    find "$base" -type f -newermt "$start" ! -newermt "$end" - print0 > "$tf" 2>/dev/null || true
    find "$base" -type d -newermt "$start" ! -newermt "$end" - print0 > "$td" 2>/dev/null || true

    # подсчет и вывод превью делаем в main, тут просто выдаем потоки
    cat "$tf"
    printf '\0'
    # сорт dirs by length desc using python if available
    python3 - <<PY 2>/dev/null || {
        cat "$td"
        rm -f "$tf" "$td"
        return 0
    }
import sys
data = sys.stdin.buffer.read().split(b'\0')
dirs = [d.decode() for d in data if d]
dirs.sort(key=lambda s: -len(s))
sys.stdout.write('\0'.join(dirs) + '\0')
PY < "$td"

    rm -f "$tf" "$td"
    return 0
}

# find_by_mask <basedir> <mask> -> files\0 separator\0 dirs\0
find_by_mask() {
    local base="$1"; local mask="$2"
    local tmp
    tmp=$(mktemp) || return 1
    # -name "$mask" finds exact; but user may pass with *; support both
    find "$base" \( -name "$mask" -o -name "${mask}*" \) -print0 > "$tmp" 2>/dev/null || true

