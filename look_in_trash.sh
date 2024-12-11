#!/bin/bash

TRASH_DIR="$HOME/trash"

if [ ! -d "$TRASH_DIR" ]; then
    echo "Le répertoire trash n'existe pas."
    exit 1
fi

echo "Contenu du répertoire trash :"
ls -l "$TRASH_DIR"

exit 0