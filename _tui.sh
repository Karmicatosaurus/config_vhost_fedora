#!/bin/bash

set -e

GRAS_ERREUR="\033[1;31m"
GRAS_BLANC="\033[1;37m"
GRAS_OK="\033[1;32m"
BLANC="\033[0m"

function menu_demarrage() 
{
    AJOUT=false
    SUPPRIME=false
    
    CHOIX=$(whiptail --title "Config VHOST" --menu "Que voulez vous faire ?" 12 40 5 "ajout" "Ajouter un projet" "supprime" "Supprimer un projet" "quitter" "Quitter"  3>&1 1>&2 2>&3)

    case "${CHOIX}" in
        "ajout")
            AJOUT=true
            ;;
        "supprime")
            SUPPRIME=true
            ;;
        "quitter")
            exit 1
            ;;
    esac
}

function msgbox()
{
    whiptail --title "${1}" --msgbox "${2}" 8 40

    if [ "${1}" = "Erreur" ]; then
        exit 1
    fi
}

function message()
{
    case "${1}" in
        "erreur")
            printf "${GRAS_BLANC} * [${GRAS_ERREUR}ERREUR${GRAS_BLANC}] ${2} !${BLANC}\n"
            ;;
        "ok")
            printf "${GRAS_BLANC} * [${GRAS_OK}OK${GRAS_BLANC}] ${2}${BLANC}\n"
            ;;
        "info")
            printf "${GRAS_BLANC} * ${2}${BLANC}\n"
            ;;
    esac
}

