#!/bin/bash

TMP_DIR="/tmp/git-clean-merge"
AUTHOR="$(git config user.name | tr -d \')"
MASTER_BRANCH="$1"
CURRENT_BRANCH="$(git branch --show-current)"
CHANGED_FILES="$(git log --author="$AUTHOR" --stat=999,999,999 --name-only --format= | sort -u)"

[ -d "$TMP_DIR" ] || mkdir "$TMP_DIR"

# Backup all changes
for f in $CHANGED_FILES; do
    cp "$f" "$TMP_DIR/${f//\//SL4SH}"
done

# Switch to master and update
git checkout "$MASTER_BRANCH" && git pull

# Merge master with changed files
for f in "$TMP_DIR"/*; do
    fb="$(basename $f)"
    cmp --silent "$f" "./${fb//SL4SH/\/}" || diff -DMERGE_CONFLICT "$f" "./${fb//SL4SH/\/}" >"$f.merged"

done

# Create new branch
git checkout -b "$CURRENT_BRANCH"_MERGED

# Copy merged files into new branch
for fm in "$TMP_DIR"/*.merged; do
    f="$(basename $fm)"
    f="${f%.merged}"
    cp "$fm" "./${f//SL4SH/\/}"
done

# Clean up
rm -rf $TMP_DIR
