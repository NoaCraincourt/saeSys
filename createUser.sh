#!/bin/bash

# Configuration du logging
LOG_FILE="/var/log/install.log"

# Fonction de logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Fonction de validation des prérequis
check_prerequisites() {
    # Vérification des privilèges root
    if [ "$EUID" -ne 0 ]; then
        echo "Erreur : Ce script doit être exécuté en tant que root (avec sudo)"
        exit 1
    fi

    # Vérification du nombre d'arguments
    if [ $# != 1 ]; then
        echo "Erreur : Veuillez fournir un fichier de configuration en argument."
        echo "Usage : $0 fichier_configuration"
        exit 1
    fi

    # Vérification de l'existence du fichier
    if [ ! -f "$1" ]; then
        echo "Erreur : Le fichier $1 n'existe pas."
        exit 2
    fi

    # Vérification de l'existence du dossier scripts
    if [ ! -d "/scripts" ]; then
        echo "Erreur : Le dossier /scripts n'existe pas."
        exit 3
    fi
}

# Fonction de nettoyage des champs
clean_field() {
    echo "$1" | xargs
}

# Fonction de création/vérification de groupe
create_or_check_group() {
    local group="$1"
    
    if ! getent group "$group" > /dev/null 2>&1; then
        log_message "Groupe $group non préexistant, création du groupe"
        if ! addgroup "$group" >> "$LOG_FILE" 2>&1; then
            log_message "Erreur lors de la création du groupe $group"
            return 1
        fi
    else
        log_message "Le groupe $group existe déjà"
    fi
    return 0
}

# Fonction de configuration du compte utilisateur
configure_user_account() {
    local login="$1"
    local user_home="$2"

    # Changement du mot de passe
    log_message "Définition du mot de passe pour $login"
    echo "$login:changeme" | chpasswd
    # Force le changement du mot de passe à la première connexion
    chage -d 0 "$login"

    # Création/modification du fichier .bashrc
    local bashrc="$user_home/.bashrc"
    
    # Sauvegarde du .bashrc original si existant
    if [ -f "$bashrc" ]; then
        cp "$bashrc" "${bashrc}.bak"
    fi

    # Ajout des alias et configuration du PATH
    cat >> "$bashrc" << EOL

# Alias personnalisés
alias e='emacs'
alias w='wireshark'

# Ajout du répertoire des scripts de gestion de la poubelle au PATH
export PATH=\$PATH:/scripts
EOL

    # Mise à jour des permissions
    chown "$login:$(id -gn "$login")" "$bashrc"
    chmod 644 "$bashrc"

    # Vérification des permissions sur le dossier /scripts
    chmod 755 /scripts/* 2>/dev/null

    log_message "Configuration du compte terminée pour $login"
}

# Fonction de création d'utilisateur
create_user() {
    local login="$1"
    local group="$2"
    local rephome="$3"
    local repconfig="$4"

    # Vérification si l'utilisateur existe déjà
    if id "$login" >/dev/null 2>&1; then
        log_message "L'utilisateur $login existe déjà"
        return 1
    fi

    # Création de l'utilisateur avec son groupe
    if ! useradd -m -s /bin/bash -g "$group" -k "$repconfig" "$login" >> "$LOG_FILE" 2>&1; then
        log_message "Erreur lors de la création de l'utilisateur $login"
        return 1
    fi

    # Configuration du répertoire personnel
    if ! usermod -d "$rephome/$login" "$login" >> "$LOG_FILE" 2>&1; then
        log_message "Erreur lors de la modification du répertoire personnel pour $login"
        return 1
    fi

    # Configuration du compte utilisateur
    configure_user_account "$login" "$rephome/$login"

    log_message "L'utilisateur $login a été créé et configuré avec succès"
    log_message "Répertoire personnel modifié pour $login : $rephome/$login"
    
    # Affichage des informations pour l'administrateur
    echo "Utilisateur $login créé avec succès"
    echo "Mot de passe temporaire : changeme"
    echo "L'utilisateur devra changer son mot de passe à la première connexion"
    
    return 0
}

# Fonction principale
main() {
    local config_file="$1"
    
    log_message "Début du script de création d'utilisateurs"
    
    local count=0
    # Utilisation de while pour lire le fichier CSV ligne par ligne
    while IFS=',' read -r login group rephome repconfig || [ -n "$login" ]; do
        # Ignorer les lignes vides
        [ -z "$login" ] && continue
        
        count=$((count + 1))
        log_message "Traitement de la ligne $count : $login, $group, $rephome, $repconfig"

        # Nettoyage des champs
        login=$(clean_field "$login")
        group=$(clean_field "$group")
        rephome=$(clean_field "$rephome")
        repconfig=$(clean_field "$repconfig")

        # Vérification des champs obligatoires
        if [ -z "$login" ] || [ -z "$group" ] || [ -z "$rephome" ] || [ -z "$repconfig" ]; then
            log_message "Erreur : champs manquants à la ligne $count"
            continue
        fi

        # Création/vérification du groupe
        create_or_check_group "$group" || continue

        # Création de l'utilisateur
        create_user "$login" "$group" "$rephome" "$repconfig" || continue
    done < "$config_file"

    log_message "Fin du script de création d'utilisateurs"
}

# Point d'entrée du script
check_prerequisites "$@"
main "$1"
exit 0
