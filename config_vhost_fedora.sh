#!/bin/bash

set -e

source ./_tui.sh
source ./_ssl.sh
source ./_vhost.sh

if [ "$EUID" -ne 0 ]; then
    msgbox "Erreur" "Le script doit être lancé avec sudo"
fi

UTILISATEUR="${SUDO_USER}"
DOSSIER_CFG_HTTPD=$(httpd -S | grep ServerRoot | awk '{print $2}' | tr -d '"')
DOSSIER_CFG_VHOSTS=${DOSSIER_CFG_HTTPD}"/conf.d"
DOSSIER_SSL_HTTPD=${DOSSIER_CFG_HTTPD}"/ssl"

DOSSIER_RACINE_WEB="/web/pub"
TLD_DOMAINE="dev"

# Appel du menu princial
menu_demarrage

case "${CHOIX}" in
    "ajout")
        NOM_VHOST=$(whiptail --title "Configuration hôte virtuel" --inputbox "Nom de l'hôte virtuel" 8 40 3>&1 1>&2 2>&3)

        if [[ -z "${NOM_VHOST}" ]]; then
            msgbox "Erreur" "Il manque le nom de l'hôte virtuel"
        fi

        TLD_VHOST=$(whiptail --title "Configuration hôte virtuel" --inputbox "TLD de l'hôte virtuel" 8 40 ${TLD_DOMAINE} 3>&1 1>&2 2>&3)

        if [[ -z "${TLD_VHOST}" ]]; then
            message "Il manque le TLD de l'hôte virtuel"
        fi

        DOSSIER_RACINE=$(whiptail --title "Configuration hôte virtuel" --inputbox "Dossier racine" 8 40 ${DOSSIER_RACINE_WEB} 3>&1 1>&2 2>&3)

        if [[ -z "$DOSSIER_RACINE" ]]; then
            DOSSIER_RACINE=${DOSSIER_RACINE_WEB}
        fi

        DOSSIER_RACINE="${DOSSIER_RACINE%/}"
        TLD_VHOST="${TLD_VHOST/#./}"

        NOM_DOMAINE=${NOM_VHOST}.${TLD_VHOST}
        DOSSIER_PUBLICATION=${DOSSIER_RACINE}/${NOM_VHOST}

        if httpd -S 2>/dev/null | grep -q "namevhost ${NOM_VHOST}"; then
            msgbox "Erreur" "L'hôte virtuel ${NOM_VHOST} existe déjà"
        fi

        if [[ -d "${DOSSIER_PUBLICATION}" ]]; then
            msgbox "Erreur" "Le dossier de l'hôte virtuel existe déjà"
        fi

        creation_certificat_ssl
        creation_virtualhost

        menu_demarrage
        ;;
    "supprime")
        suppression_virtualhost

        menu_demarrage
        ;;
    "quitter")
        exit 1
        ;;
esac
