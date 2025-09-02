#!/usr/bin/env bash
set -euo pipefail

# главный скрипт генератора файлов
# пример:
# ./main.sh /opt/test 4 az 5 az.az 3kb

# Путь к вспомогательным библиотекам
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib_namegen.sh"
source "$DIR/lib_utils.sh"


