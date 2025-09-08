#!/usr/bin/env bash
# Функции генерации имен (каждая буква используется минимум 1 раз, порядок сохранен).

# generate <letters> <min_len>
generate_name() {
    local letters="$1"
    local min_len="$2"
    letters=$(echo "$letters" | tr '[:upper:]' '[:lower:]')
    local -a chars
    local i
    for ((i=0;i<${#letters};i++)); do
        chars[i]="${letters:i:1}"
    done

    local name=""
    for c in "${chars[@]}"; do
        name+="$c"
    done

    local idx=0
    # если letters пустые - возврат пустой строки
    if [ "${#chars[@]}" -eq 0 ]; then
        echo ""
        return
    fi

    while [ "${#name}" -lt "$min_len" ]; do
        name+="${chars[idx]}"
        idx=$(( (idx + 1) % ${#chars[@]} ))
    done

    echo "$name"
}

# generate_ext <letters> <max_len>
generate_ext() {
    local letters="$1"
    local max_len="$2"
    letters=$(echo "$letters" | tr '[:upper:]' '[:lower:]')
    local base
    base=$(generate_name "$letters" "${#letters}")
  
