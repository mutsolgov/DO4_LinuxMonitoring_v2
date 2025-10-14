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
       
