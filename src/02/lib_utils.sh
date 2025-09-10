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

# Создаем файла размера MB (используем dd)
# create_file_mb <path> <size_mb>
create_file_mb() {
    local path="$1"
    local size_mb="$2"
    # используем dd с bs=1M
    dd if=/dev/zero of="$path" bs=1M count="$size_mb" status=none 2>/dev/null
    return $?
}

#log_entry <msg> (LOGFILE должен быть установлен глобально)
log_entry() {
    local msg="$1"
    echo "$msg" >> "$LOGFILE"
}
