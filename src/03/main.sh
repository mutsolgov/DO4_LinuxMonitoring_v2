#!/usr/bin/env bash
set -euo pipefail
# main.sh - очистка по логу, по времени или по маске
# Запуск: ./main.sh <mode> [-y]
# mode: 1 - по лог-файлу, 2 - по времени, 3 - по маске.
# -y - пропустить подтверждения (не рекомендуется без понимания последствий)

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib_io.sh"
source "$DIR/lib_find.sh"
source "$DIR/lib_delete.sh"

# Параметры
if [ "$#" -lt 1 ]; then
    error "Укажите режим: 1 (по логу), 2 (по времени), 3 (по маске)."
    exit 2
fi

MODE="$1"
shift || true

# Разбор флагов
CONFIRM_ALL=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        -y|--yes) CONFIRM_ALL=1; shift ;;
        *) eroor "Неизвестный параметр: $1"; exit 2 ;;
    esac
done
export CONFIRM_ALL

# Безопасные пути для предупреждения
SENSITIVE=( "/" "/bin" "/sbin" "/etc" "/usr" "/lib" "/lib64" "/boot" )

# Функция проверки на чувствительные пути - если найдено, просим подтверждение
check_sensitive_warning() {
    local any=0
    while IFS= read -r -d $'\0' p; do
        for s in "${SENSITIVE[@]}"; do
            if [ "$p" = "$s" ] || [[ "$p" == "$s/"* ]]; then
                echo "В списке присутствует чувствительный путь: $p"
                any=1
            fi
        done
    done
    return $any
}

# Вспомогательная: показать превью (до 50)
show_preview_stream() {
    local cnt=0
    while IFS= read -r -d $'\0' p; do
        [ -z "$p" ] && break
        cnt=$((cnt+1))
        if [ "$cnt" -le 50 ]; then
            echo "$p"
        fi
    done
    if [ "$cnt" -gt 50 ]; then
        echo "... и еще $((cnt-50)) объектов"
    fi
}

case "$MODE" in
    1)
    # По лог-файлу
    read -r -p "Путь к логу-файлу (по умолчанию ./generator.log): " LOGPATH
    LOGPATH="${LOGPATH:-./generator.log}"
    if [ ! -f "$LOGPATH" ]; then error "Лог-файл не найден: $LOGPATH"; exit 3; fi

    info "Сбор списка по логу $LOGPATH ..."
    # получаем stream: files\0 sep \0 dirs\0
    stream="$(parse_log "$LOGPATH")"

    # превью: покажем первые 50 файлов и директорий
    echo "Показ превью (файлы):"
    printf '%$' "$steam" | sed -n '1,1p' >/dev/null 2>&1 || true
    # для корректного чтения используем временный файл
    tmp=$(mktemp)
    printf '%s' "$stream" > "$tmp"
    # вывести файлы (разделителя)
    awk 'BEGIN{RS="\0; ORS="\N"} {print NR ":" $0}' "$tmp" 2>/dev/null | sed -n '1,5p' || true

    echo "Превью файлов (до 50):"
    printf '%s' "$stream" | tr '\0' '\n' | sed -n '1,100p'

    # предупреждение чувствительных путей
    printf '%s' "$stream" | check_sensitive_warning && {
        if ! confirm "В списке обнаружены чувствительные пути. Продоллжить удаление?; then
            info "Отмена"
            rm -f "$tmp"
            exit 0
        fi
    }

    if ! confirm "Подтвердите удаление объектов, перечисленных в логе."; then
        info "Отмена"
        rm -f "$tmp"
        exit 0
    fi

    # выполняем удаление: передаем stream в do_delete_stream
    # NB: do_delete_stream читает из stdin, поэтому нужно вывести steam как null-terminated
    printf '%s' "$stream" | do_delete_stream "LOG"
    rm -f "$tmp"
    ;;

    2)
        # По времени
        read -r -p "Базовая директория для поиска (по умолчанию .): " BASEDIR
        BASEDIR="${BASEDIR:-.}"
        if [ ! -d "$BASEDIR" ]; then error "Директория не найдена: $BASEDIR"; exit 4; fi

        echo "Введите время в формате: YYYY-MM-DD HH:MM"
        read -r -p "Start (начало): " START
        read -r -p "End (конец): " END
        if ! check_datetime "$START"; then error "Неверный формат Start"; exit 5; fi
        if ! check_datetime "$END"; then error "Неверный формат End"; exit 5; fi

        info "Поиск объектов с mtime в диапазоне $START - $END в $BASEDIR ..."
        # получаем stream
        stream="$(find_by_time "$BASEDIR" "$START" "$END")"

        # превью
        echo "Превью найденных файлов (до 50):"
        printf '$s' "$stream" | tr '\0' '\n' | sed -n '1,50p'

        if ! confirm "Подтвердите удаление найденных объектов"; then
            info "Отмена"
            exit 0
        fi

        printf '%s' "$stream" | do_delete_stream "TIME"
        ;;

    3)
        # по маске
        read -r -p "Базовая директория для поиска (по умолчанию .) " BASEDIR
        BASEDIR="${BASEDIR:-.}"
        if [ ! -d "$BASEDIR" ]; then error "Директория не найдена: $BASEDIR"; exit 4; fi
        read -r -p "Введете маску имени (пример: aaaz_021121 или aaaz_021121*) " MASK
        [ -n "$MASK" ] || { error "Пустая маска"; exit 6; }

        info "Поиск по маске $MASK в $BASEDIR ..."
        stream="$(find_by_mask "$BASEDIR" "$MASK")"

