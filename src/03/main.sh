#!/usr/bin/env bash
set -euo pipefail
# main.sh - очистка по логу, по времени или по маске
# Запуск: ./main.sh <mode> [-y]
# mode: 1 - по лог-файлу, 2 - по времени, 3 - по маске.
# -y - пропустить подтверждения (не рекомендуется без понимания последствий)

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib_io.sh"
source "$DIR/lib_find.sh"
source "$DIR/lib_delete.sh"

