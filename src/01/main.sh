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

# Текущая дата для суффикса (DDMMYY)
DATE_SUFFIX=$(date '+%d%m%y')

# ===== Основной цикл: создаем цепочку вложенных каталогов =====
current_path="$BASE_PATH"

# Чтобы имена файлов были различны в одной папке - будем варьировать min_len
for (( depth_i=1; depth_i<=DEPTH; depth_i++ )); do
    # Проверка места
    if ! check_free_space; then
        echo "Доступное место на / ≤ 1GB - остановка." >&2
        exit 2
    fi

    # Генерация имени папки (минимальная длина 4)
    folder_base=$(generate_name "$FOLDER_LETTERS" 4)
    folder_name="${folder_base}_${DATE_SUFFIX}"
    current_path="$current_path/$folder_name"

    safe_mkdir "$current_path" || exit 1

    # Создаем файлы в этой папке
    for (( f=1; f<=FILES_PER_FOLDER; f++ )); do
        if ! check_free_space; then
            echo "Доступное место на / ≤ 1GB - остановка." >&2
            exit 2
        fi

        # Для уникальности увеличиваем длину имени на f (чтобы получить разные имена)
        file_base=$(generate_name "$NAME_LETTERS" $((4 + (f-1))))
        file_name="${file_base}_${DATE_SUFFIX}"
        # генерируем расширение (максимум 3 символа)
        file_ext=$(generate_ext "$EXT_LETTERS" 3)
        fullfile="$current_path/${file_name}.${file_ext}"

        # Создаем файл указанного размера
        if create_file_of_size "$fullfile" "$SIZE_KB"; then
            local_dt=$(date '+%F %T')
            # размер в байтах
            size_bytes=$(stat -c%s "$fullfile" 2>/dev/null || echo "$((SIZE_KB*1024))")
            # Запись в лог: TYPE|PATH|DATE|SIZE_BYTES
            log_entry "FILE|$fullfile|$local_dt|$size_bytes"
        else
            echo "Ошибка при создании файла $fullfile" >&2
        fi
    done
done

echo "Готово. Лог: $LOGFILE"
exit 0
