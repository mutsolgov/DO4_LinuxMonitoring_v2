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

# 4) FILES_PER_FOLDER integer >0
if ! [[ "$FILES_PER_FOLDER" =~ ^[0-9]+$ ]] || [ "$FILES_PER_FOLDER" -le 0 ]; then
    echo "Ошибка: FILES_PER_FOLDER должен быть положительным целым." >&2
    exit 1
fi

# 5) FILE_LETTERS format name.ext
if ! [[ "$FILE_LETTERS" =~ ^[A-Za-z]{1,7}\.[A-Za-z]{1,3}$ ]]; then
    echo "Ошибка: FILE_LETTERS должен быть формата nameletters.extletters (name ≤7, ext ≤3)." >&2
    exit 1
fi
NAME_LETTERS="${FILE_LETTERS%%.*}"
EXT_LETTERS="${FILE_LETTERS##*.}"

# 6) SIZE_PARAM like 'Nkb' and N<=100
if ! [[ "$SIZE_PARAM" =~ ^([0-9]{1,3})([kK][bB])$ ]]; then
    echo "Ошибка: SIZE должен быть формата Nkb (например 3kb)." >&2
    exit 1
fi
SIZE_KB="${BASH_REMATCH[1]}"
if [ "$SIZE_KB" -le 0 ] || [ "$SIZE_KB" -gt 100 ]; then
    echo "Ошибка: SIZE должен быть в диапазоне 1...100 KB." >&2
    exit 1
fi

# Создаем базовую папку, если нужно
mkdir -p "$BASE_PATH" || { echo "Не удалось создать.достать $BASE_PATH"; exit 1; }

# Лог-файл в BASE_PATH/generator.log
LOGFILE="$BASE_PATH/generator.log"
touch "$LOGFILE" || { echo "Не могу создать лог $LOGFILE"; exit 1; }

