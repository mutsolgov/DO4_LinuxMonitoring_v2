#!/usr/bin/env bash
# Утилиты: проверка места, создание файла, лог.

# Парсим доступное место на "/" (в KB)
get_avail_kb_root() {
    # возвращаем число (KB) или пустую строку при ошибке
    df --output=avail -k / 2>/dev/null | tail -n1 | tr -d ' '
}

#check_free_space <limit_kb>
# возвращает 0 если свободного места > limit_kb, иначе 1
check_free_space() {
    local limit_kb="$1"
    local avail
    avail=$(get_avail_kb_root)
    if [ -z "$avail" ]; then
        return 1
    fi
    if [ "$avail" -le "$limit_kb" ]; then
        return 1
    fi
    return 0
}

