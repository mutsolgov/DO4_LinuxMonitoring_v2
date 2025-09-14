#!/usr/bin/env bash
set -euo pipefail

# Запуск: ./main.sh az az.az 3Mb

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib_namegen.sh"
source "$DIR/lib_utils.sh"

usage() {
    cat <<EOF
Использование:
    $0 <FOLDER_LETTERS> <FILE_LETTERS> <SIZEmb>
Пример:
    $0 az az.az 3Mb

По умолчанию запускается в SAFE-режиме (gпесочница ./sandbox_fs).
Для тестирования порог остановки используйте переменную окружения FREE_LIMIT_KB (в KB).
EOF
    exit 1
}

if [ "$#" -ne 3 ]; then
    usage
fi

FOLDER_LETTERS="$1"
FILE_LETTERS="$2"   # формат name.ext
SIZE_PARAM="$3"     # например 3Mb или 10Mb

# Валидация
if ! [[ "$FOLDER_LETTERS" =~ ^[A-Za-z]{1,7}$ ]]; then
    echo "Ошибка: FOLDER_LETTERS - только латиница, 1..7 символов." >&2
    exit 1
fi

if ! [[ "$FILE_LETTERS" =~ ^[A-Za-z]{1,7}\.[A-Za-z]{1,3}$ ]]; then
    echo "Ошибка: FILE_LETTERS должен быть формата name.ext (name ≤7, ext ≤3)." >&2
    exit 1
fi

if ! [[ "$SIZE_PARAM" =~ ^([0-9]{1,3})([mM][bB])$ ]]; then
    echo "Ошибка: SIZE должен быть формата NMb, где N 1..100." >&2
    exit 1
fi
SIZE_MB="${BASH_REMATCH[1]}"
if [ "$SIZE_MB" -le 0 ] || [ "$SIZE_MB" -gt 100 ]; then
    echo "Ошибка: SIZE: должен быть в диапазоне 1..100 MB." >&2
    exit 1
fi

NAME_LETTERS="${FILE_LETTERS%%.*}"
EXT_LETTERS="${FILE_LETTERS##*.}"

# Поведение безопасности:
# По умолчанию - SAFE режим (создаем все в ./sandbox_fs).
# Если вы хотите тестировать на реальной FS (опасно!), поменяйте переменную ENV RUN_DANGEROUS на "1" вручную.
RUN_DANGEROUS="${RUN_DANGEROUS:-1}"

# Порог свободного места (в KB).
FREE_LIMIT_KB="${FREE_LIMIT_KB:-1048576}"

# Параметры генерации
DATE_SUFFIX=$(date '+%d%m%y')
LOGROOT="${PWD}"
LOGFILE="$LOGROOT/generator.log"
touch "$LOGFILE"

# куда писать.....
BASE_DIRS=(/tmp /var/tmp /opt /srv /home)

# ограничения: глубина до 100
MAX_DEPTH=100
# максимальное случайное число файлов в папке (можно изменить)
MAX_FILES_PER_FOLDER=12

# Стартовые метрики
START_TIME=$(date '+%s')
START_TIME_H=$(date '+%F %T')
log_entry "START|$START_TIME_H|FREE_LIMIT_KB=$FREE_LIMIT_KB|RUN_DANGEROUS=$RUN_DANGEROUS"

# создаем базовые каталоги
for base in "${BASE_DIRS[@]}"; do
    if [[ "$base" =~ bin|sbin ]]; then
        echo "Пропускаем путь: $base" >&2
        continue
    fi
    mkdir -p "$base"
done

# Основной генератор
# Для каждого базового каталога создаем случайную вложенную цепочку (глубина 1..MAX_DEPTH)
for base in "${BASE_DIRS[@]}"; do
    # проверка места
    if ! check_free_space "$FREE_LIMIT_KB"; then
        echo "Свободное место на / ≤ $FREE_LIMIT_KB KB - остановка." >&2
        break
    fi

    # случайная глубина от 1 до MAX_DEPTH (чтобы тесты не были слишком долгим, в SAFE режиме ограничим 12)
    if [ "$RUN_DANGEROUS" -eq 1 ]; then
        depth=$(( (RANDOM % MAX_DEPTH) + 1 ))
    else
        depth=$(( (RANDOM % 12) + 1 ))
    fi

