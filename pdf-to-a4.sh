#!/bin/sh

TMP_PDF="/tmp/pdfposter.pdf"
INPUT=`zenity --file-selection --title="Select a File"`
pdfposter -s1 "$INPUT" "$TMP_PDF"
PAGES=$(pdfinfo $TMP_PDF | grep ^Pages: | tr -dc '0-9')

non_blank() {
    for i in $(seq 1 $PAGES)
    do
        PERCENT=$(gs -o -  -dFirstPage=${i} -dLastPage=${i} -sDEVICE=inkcov ${TMP_PDF} | grep CMYK | nawk 'BEGIN { sum=0; } {sum += $1 + $2 + $3 + $4;} END { printf "%.5f\n", sum } ')
        if [ $(echo "$PERCENT > 0.001" | bc) -eq 1 ]
        then
            echo $i
            # echo $i 1>&2
        fi
        echo -n . 1>&2
    done | tee "${INPUT%.*}.tmp"
    echo 1>&2
}

set +x
pdftk "${TMP_PDF}" cat $(non_blank) output "${INPUT%.*}.new.pdf"

if [ $? -eq 0 ]
then
   rm "${INPUT%.*}.tmp"
   rm "$TMP_PDF"
fi
