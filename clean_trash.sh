#!/bin/bash

TRASH_DIR="$HOME/trash"

if [ ! -d "$TRASH_DIR" ]; then
    echo "Le répertoire trash n'existe pas."
    exit 1
fi

rm -rf "$TRASH_DIR"/*
echo "Le répertoire trash a été vidé."

exit 0