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

