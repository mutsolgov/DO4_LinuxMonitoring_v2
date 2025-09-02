#!/usr/bin/env bash
set -euo pipefail

# главный скрипт генератора файлов
# пример:
# ./main.sh /opt/test 4 az 5 az.az 3kb

# Путь к вспомогательным библиотекам
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib_namegen.sh"
source "$DIR/lib_utils.sh"

usage() {
    cat <<EOF
Использование:
    $0 <ABS_PATH> <DEPTH> <FOLDER_LETTERS> <FILES_PER_FOLDER> <FILE_LETTERS> <SIZEkb>
Пример:
    $ /opt/test 4 az 5 az.az 3kb
Где:
    ABS_PATH           - абсолютный путь, где создавать (должен начинаться с /)
    DEPTH              - количество вложенных папок (положительное целое)
    FOLDER_LETTERS     - буквы для имен папок (только латиница, не более 7 символов)
    FILES_PER_FOLDER   - количество файлов в каждой папке (положительное целое)
    FILE_LETTERS       - формат: <nameletters>.<extletters> (name ≤7, ext ≤3)
    SIZEkb             - размер файлов в килобайтах, например 3kb (целое <=100)
EOF
    exit 1
}

# === Валидация входных параметров ===
if [ "$#" -ne 6 ]; then
    echo "Ошибка: нужно 6 параметров." >&2
    usage
fi

BASE_PATH="$1"
DEPTH="$2"
FOLDER_LETTERS="$3"
FILES_PER_FOLDER="$4"
FILE_LETTERS="$5"
SIZE_PARAM="$6"

# Проверки
# 1) BASE_PATH абсолютный
if [[ "$BASE_PATH" != /* ]]; then
    echo "Ошибка: параметр 1 должен быть абсолютным путем." >&2
    exit 1
fi

# 2) DEPTH integer >0
if ! [[ "$DEPTH" =~ ^[0-9]+$ ]] || [ "$DEPTH" -le 0 ]; then
    echo "Ошибка: DEPTH должен быть положительным целым." >&2
    exit 1
fi

# 3) FOLDER_LETTERS only letters, len <=7
if ! [[ "$FOLDER_LETTERS" =~ ^[A-Za-z]+$ ]] || [ "${#FOLDER_LETTERS}" -gt 7 ]; then
    echo "Ошибка: FOLDER_LETTERS - только латинские буквы, не более 7." >&2
    exit 1
fi

