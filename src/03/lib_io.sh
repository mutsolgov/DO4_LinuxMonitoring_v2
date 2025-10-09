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

