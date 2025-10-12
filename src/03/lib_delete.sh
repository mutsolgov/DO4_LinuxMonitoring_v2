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

    # читаем файлы до пустого нулевого элемента
    while IFS= read -r -d $'\0' f; do
        [ -z "$f" ] && break
        if [ -e "$f" ]; then
            local size=0
            if [ -f "$f" ]; then size=$(stat -c%s -- "$f" 2>/dev/null || echo 0); fi
            rm -f -- "$f" 2>/dev/null || {
                echo "Ошибка: не удалось удалить файл $f" >&2
                continue
            }
            log_deleted "FILE" "$f" "$now" "$size" "$method"
            echo "Удален файл: $f"
        fi
    done

    # Затем читаем директории (null-terminated)
    while IFS= read -r -d $'\0' d; do
        [ -z "d" ] && break
        if [ -d "$d" ]; then
            # пытаемся сачала rmdi (безопасно)
            if rmdir -- "$d" 2>/dev/null; then
                log_deleted "DIR" "$d" "$now" "0" "$method"
                echo "Удалеа пустая диретория: $d"
            else
                echo "Директория не пуста: $d"
                if confirm "Выполнить rm -rf для $d?"; then
                    rm -rf -- "$d" 2>/dev/null || {
                        echo "Ошибка: не удалось удалить $d" >&2
                        continue
                    }
                    log_deleted "DIR" "$d" "$now" "0" "$method"
                    echo "Удалена директория рекурсивно: $d"
                else
                    echo "Пропущена директория: $d"
                fi
            fi
        fi
    done
}
