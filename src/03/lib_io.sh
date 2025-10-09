#!/usr/bin/env bash

# Пишем ошибки на stderr
error() {
    echo "Ошибка: $*" >&2
}

info() {
    echo "$*"
}

