#!/bin/bash

TRASH_DIR="$HOME/trash"

if [ ! -d "$TRASH_DIR" ]; then
    echo "Le répertoire trash n'existe pas."
    exit 1
fi

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Erreur : Un ou deux arguments sont requis."
    exit 1
fi

if [ ! -e "$TRASH_DIR/$1" ]; then
    echo "Erreur : Le fichier ou répertoire spécifié n'existe pas dans le trash."
    exit 2
fi

if [ $# -eq 1 ]; then
    cp -r "$(readlink -f "$TRASH_DIR/$1")" "$HOME/"
    echo "$1 restauré dans le répertoire HOME."
elif [ $# -eq 2 ]; then
    if [ ! -d "$2" ]; then
        echo "Erreur : Le deuxième argument doit être un répertoire valide."
        exit 3
    fi
    cp -r "$(readlink -f "$TRASH_DIR/$1")" "$2/"
    echo "$1 restauré dans le répertoire $2."
fi

rm "$TRASH_DIR/$1"
exit 0