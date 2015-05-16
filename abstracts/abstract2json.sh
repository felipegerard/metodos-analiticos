#! /bin/bash
# NOTA: Hay que quitar la coma del ultimo registro
# $1 ruta de los datos
# $2 es el numero de cores a usar

export LC_CTYPE=C
export LC_ALL=C
export LANG=C

find $1 -iname "*txt" \
| parallel -j $2 --eta "< {} ./abstract2json_onerow.sh" \
| awk 'BEGIN {i=1; print "{"} \
    /{/ {print "\"" i "\":" "{"; i++} \
    !/{/ {print} \
    END {print "}"}'

export LC_CTYPE=UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
