#!/usr/bin/env bash
# Функция для генерации имен папок.файлов с сохранением порядка букв

# generate_name <letters> <min_len>
# Возвращает строку длиной >= min_len, содержащую каждую букву из <letters> хотя бы один раз,
# и повторяющую букву в том же порядке (никогда не ставя буквы в обратном порядке).
generate_name() {
    local letters="$1"
    local min_len="$2"
    # нормализуем: в нижний регистр
    letters=$(echo "$letters" | tr '[:upper:]' '[:lower:]')
    local -a chars
    local i
    for (( i=0; i<${#letters}; i++ )); do
        chars[i]="${letters:i:1}"
    done

    # Начинаем с одной копии каждой буквы в порядке
    local name=""
    for c in "${chars[@]}"; do
        name+="$c"
    done

    # Добавляем буквы в порядке, пока не достигнем min_len
    local idx=0
    while [ "${#name}" -lt "$min_len" ]; do
        name+="${chars[idx]}"
        idx=$(( (idx + 1) % ${#chars[@]} ))
    done

    echo "$name"
}

# generate_ext <letters> <max_len>
# Похожая логика для расширения - возвращает строку длиной >= len(letters) и <= max_len
# Если letters длина > max_len - это ошибка обработанная ранее.
generate_ext() {
    local letters="$1"
    local max_len="$2"
    letters=$(echo "$letters" | tr '[:upper:]' '[:lower:]')
    local base
    base=$(generate_name "$letters" "${#letters}")
    # обрезаем, если получилось длинее max_len, но при этом нужно сохранить порядок букв:
    if [ "${#base}" -gt "$max_len" ]; then
        base="${base:0:$max_len}"
    fi
    echo "$base"
}
