#!/bin/bash

function findRootDirRec() {
	DIR_UP="$(dirname $1)/"
	DIR_FOUND="$(echo "${DIR_LIST[@]}" | grep "^$DIR_UP$")"
	[[ -z "$DIR_FOUND" ]] && echo $1 || findRootDir $DIR_FOUND
}

function showChangesRec() {
	for line in $DIR_LIST; do
		ROOT_DIR="$(findRootDir $line)"
		[[ ! "$ROOT_DIR_LIST" =~ $ROOT_DIR ]] && ROOT_DIR_LIST+="$ROOT_DIR.|"
	done

	[ -z "$ROOT_DIR_LIST" ] && echo "${ALL_LIST[@]}" || echo "${ALL_LIST[@]}" | egrep -v "${ROOT_DIR_LIST%?}"
}

function findRootDir(){
	DIR_LIST_TMP="$(echo $@ | tr ' ' '\n')"
	ROOT_DIR_LIST="$(echo $DIR_LIST_TMP | awk '{print $1}')"
	for line in $DIR_LIST_TMP; do
		[[ ! "$line" =~ $ROOT_DIR_LIST ]] && ROOT_DIR_LIST+="|$line"
	done

	echo $ROOT_DIR_LIST
}

function showChanges() {
	DIR_LIST_1="$(findRootDir ${DIR_LIST[@]})"
	DIR_LIST_REVERSE="$(echo $DIR_LIST_1 | tr '|' '\n' | tac)"
	DIR_LIST_2="$(findRootDir ${DIR_LIST_REVERSE[@]})"
	DIR_LIST_2="$(echo "$DIR_LIST_2" | sed 's#|#\.|#g' | sed 's/$/./')"

 	[ "$DIR_LIST_2" = "." ] && echo "${ALL_LIST[@]}" || echo "${ALL_LIST[@]}" | egrep -v "$DIR_LIST_2"
}

function Rsync() {
	SRC_DIR="$1"
    DEST_DIR="$2"
    shift; shift

    for arg in "$@"; do
    	EXCL_LIST+="$arg\n"
    done

    if [ -z "$EXCL_LIST" ]; then
    	ALL_LIST="$(rsync -nrl --out-format='%i |%n' --delete $SRC_DIR $DEST_DIR | sed '/+++++++++/s/+/P/10g' | sed '/+++++++++/! s/+/P/g')"
    else
    	ALL_LIST="$(rsync -nrl --out-format='%i |%n' --delete --exclude-from=<(echo -e "$EXCL_LIST") $SRC_DIR $DEST_DIR | sed '/+++++++++/s/+/P/10g' | sed '/+++++++++/! s/+/P/g')"
    fi

	DIR_LIST="$(echo "${ALL_LIST[@]}" | egrep "^cd|^\*deleting" | grep '/$' | cut -d '|' -f2 | sed 's/ //g' | tr '|' '\n')"

	showChanges

	read -p "Sync? (Type: yes) : " input
	if [[ "$input" == "yes" ]]; then
		if [ -z "$EXCL_LIST" ]; then
	    	rsync -a --delete $SRC_DIR $DEST_DIR
	    else
	    	rsync -a --delete --exclude-from=<(echo -e "$EXCL_LIST") $SRC_DIR $DEST_DIR
	    fi
	fi
}

Rsync "$@"

: <<'EOC'
$TERMINAL -e bash -c "$(declare -f rsyncUSB); $(declare -f showChanges); $(declare -f findRootDir); rsyncUSB $@"

rsync -nrl --out-format='%i %n' --delete $SRC_DIR $DEST_DIR --exclude-from=$EXCL_FILE --exclude-from=<(\
	rsync -nrl --out-format='%i |%n' --delete --exclude-from=$EXCL_FILE $SRC_DIR $DEST_DIR \
		| egrep "^cd|^\*deleting" | grep '/$' | cut -d '|' -f2 | sed -e 's/$/\*/')

function rsyncUSB() {
    SRC_DIR="$HOME/"
    DEST_DIR="/run/media/$USER/$(ls /run/media/$USER/)/"
    read -r -d '' EXCL_FILE <<'EOF'
/.*
/.*/
/Qemu/
/Synology/
EOF
    Rsync.sh "$EXCL_FILE" $SRC_DIR $DEST_DIR
}
EOC
