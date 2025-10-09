#!/usr/bin/env bash

# Пишем ошибки на stderr
error() {
    echo "Ошибка: $*" >&2
}

info() {
    echo "$*"
}

# Подтверждение пользователя (если CONFIRM_ALL=1, подтверждение пропускается)
# confirm "Сообщение" -> return 0 если подтверждено, иначе return 1
confirm() {
    local msg="${1:-Продолжить?}"
    if [ "${CONFIRM_ALL:-0}" -eq 1 ]; then
        return 0
    fi
    read -r -p "$msg [y/N]: " ans
    case "$ans" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# Быстрая проверка формата времени (YYYY-MM-DD HH:MM)
check_datetime() {
    local ts="$1"
    if ! date -d "$ts" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}
