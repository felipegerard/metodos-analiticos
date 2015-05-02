#! /bin/bash

tr -d '\r' \
| tr '\n' '|' \
| sed -e 's/||/ <br> <br> /g' \
      -e 's/|/ <br> /g' \
| sed -E -e 's/ <br> <br> ([A-Z]+;? )/||\1/g' \
| tr '|' '\n' \
| sed -e 's/\./<punto>/g' \
      -e 's/,/<coma>/g' \
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
      -e 's/[^a-zA-Z_<> ]//g' \
| grep -E "^[A-Z]+;?" \
| sed -E -e 's/^([A-Z]+)(<punto_coma> [A-Z]+)? <br> /"\1\2":"/' \
	 -e 's/$| $/"/' \
| grep '^"' \
| sed -e '$ ! s/$/,/' \
| awk 'BEGIN {print "{"} {print} END {print "}"}'
