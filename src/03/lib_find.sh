#!/usr/bin/env bash

# lib_find.sh - функции поиска для cleanup
# Возвращает списки в null-terminated потоках (безопасно для пробелов).

# parse_log <logpath> -> печатает сначала список файлов (null-terminated), потом строка SEP, потом список директорий (null-terminated)
parse_log() {
    local logpath="$1"
    local tmpf
    # Читаем лог (ожидаем формат TYPE|PATH|DATE|SIZE)
    # Запишем файлы в tmp_files, каталоги в tmp_dirs
    local tmp_files tmp_dirs
    tmp_files=$(mktemp) || return 1
    tmp_dirs=$(mktemp) || return 1

   
