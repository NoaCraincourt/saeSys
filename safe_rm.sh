#!/bin/bash

TRASH_DIR="$HOME/trash"

if [ $# -ne 1 ]; then
    echo "Erreur : Un seul argument est requis."
    exit 1
fi

if [ ! -e "$1" ]; then
    echo "Erreur : Le fichier ou répertoire spécifié n'existe pas."
    exit 2
fi

if [ ! -d "$TRASH_DIR" ]; then
    mkdir -p "$TRASH_DIR"
fi

ln -s "$(realpath "$1")" "$TRASH_DIR/"
rm -rf "$1"
echo "$1 déplacé dans $TRASH_DIR sous forme de lien symbolique."

exit 0