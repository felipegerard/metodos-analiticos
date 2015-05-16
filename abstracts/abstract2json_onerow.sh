#! /bin/bash

sed -E -e 's/^(.+:)/<br>\1/' \
| tr '\n' '|' \
| sed -E -e 's/\|<br>/<n>/g' -e 's/\|/<br>/g' -e 's/<n>/\|/g' \
| tr '|' '\n' \
| tr '\t' ' ' \
| sed -E 's/ +/ /g' \
| sed -e 's/\./<punto>/g' \
    -e 's/,/<coma>/g' \
    -e 's/:/<sep_json>/' \
    -e 's/:/<dos_puntos>/g' \
    -e 's/;/<punto_coma>/g' \
    -e 's/\*/<asterisco>/g' \
    -e 's/"/<comillas_dobles>/g' \
    -e "s/'/<comillas_simples>/g" \
    -e 's/`/<backtick>/g' \
    -e 's/#/<gato>/g' \
    -e 's/\[/<abre_corchetes>/g' \
    -e 's/\]/<cierra_corchetes>/g' \
    -e 's/(/<abre_parent>/g' \
    -e 's/)/<cierra_parent>/g' \
    -e 's/-/<guion>/g' \
    -e 's/&/<ampersand>/g' \
    -e 's/\//<diagonal>/g' \
    -e 's/[^0-9a-zA-Z_<> ]//g' \
    -e 's/<sep_json>/:/g' \
| awk -F':' 'BEGIN {print "{"} {print "\"" $1 "\":\"" $2 "\","} END {print "},"}' \
| sed -E -e 's/^"<br>/"/' -e 's/" | "/"/g' \
| egrep "^([\{\}])|(\"(Title|Date|Award Number|Investigator|Sponsor|Fld Applictn|Abstract))" \
| tr '\n' '|' \
| sed -E 's/,\|+\}/\|\}/g' \
| tr '|' '\n'

#| sed -E 's/(^"Abstract":".*"),/\1/'
