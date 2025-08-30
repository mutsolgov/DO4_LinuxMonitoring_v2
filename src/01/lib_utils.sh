#!/usr/bin/env bash
# Общие утилиты: валидация входных параметров, проверка места, создание файла и лог.

# Проверка свободного места в разделе / (в килобайтах)
# Возвращает 0 если больше 1GB, 1 - если меньше или равно 1GB.
check_free_space() {
    # Получаем доступное пространство в KB
    local avail_kb
    avail_kb=$(df --output=avail -k / | tail -1 | tr -d ' ')
    # 1 GB в KB = 1048576
    local limit_kb=1048576
    if [ -z "$avail_kb" ]; then
        echo "Не удалось определить свободное место" >&2
        return 1
    fi
    if [ "$avail_kb" -le "$limit_kb" ]; then
        return 1
    fi
    return 0
}

# create_file <fullpath> <size_kb>
# Создает файл заданного размера (в KB) и возвращает 0 или 1 при ошибке.
create_file_of_size() {
    local fpath="$1"
    local size_kb="$2"
    # используем ddдля переносимости
    dd if=/dev/zero of="$fpath" bs=1024 count="$size_kb" status=none 2>/dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
    return 0
}

