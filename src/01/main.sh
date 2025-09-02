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

