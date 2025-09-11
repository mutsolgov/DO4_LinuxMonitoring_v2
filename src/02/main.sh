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

