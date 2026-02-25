#!/bin/bash

set -e

function creation_certificat_ssl()
{
    DOSSIER_CRT_CA="/home/${UTILISATEUR}/.local/share/HttpCerts"

    if [[ ! -d "${DOSSIER_CRT_CA}" ]]; then
        message "info" "Création du dossier ${DOSSIER_CRT_CA}"
        mkdir -p ${DOSSIER_CRT_CA}
    fi

    if [ ! -f "${DOSSIER_CRT_CA}/ca.key" ]; then

        CN_CA=$(whiptail --title "Creation certifical SSL" --inputbox "Nom principal de l'entité" 8 40 3>&1 1>&2 2>&3)

        if [[ -z "${CN_CA}" ]]; then
            msgbox "Erreur" "Il manque le nom principal de l'entité"
        fi

        O_CA=$(whiptail --title "Creation certifical SSL" --inputbox "Nom de l'organisation" 8 40 3>&1 1>&2 2>&3)

        if [[ -z "${O_CA}" ]]; then
            msgbox "Erreur" "Il manque le nom de l'organisation"
        fi

        message "info" "Création du CA"
        openssl genrsa -out ${DOSSIER_CRT_CA}/ca.key 4096
        openssl req -x509 -new -nodes -key ${DOSSIER_CRT_CA}/ca.key -sha256 -days 3650 \
        -out ${DOSSIER_CRT_CA}/ca.crt \
        -subj "/CN=${CN_CA}/O=${O_CA}" \
        -addext "basicConstraints=critical,CA:TRUE" \
        -addext "keyUsage=critical,keyCertSign,cRLSign"
    else
        message "info" "CA déjà présent"
    fi

    if [ ! -d "${DOSSIER_SSL_HTTPD}" ]; then
        message "info" "Création du dossier ${DOSSIER_SSL_HTTPD}"
        mkdir ${DOSSIER_SSL_HTTPD}
    fi

    message "info" "Création certificats SSL"
    openssl genrsa -out ${DOSSIER_SSL_HTTPD}/${NOM_DOMAINE}.key 4096
    openssl req -new -key ${DOSSIER_SSL_HTTPD}/${NOM_DOMAINE}.key  -out ${DOSSIER_SSL_HTTPD}/${NOM_DOMAINE}.csr -subj "/CN=${NOM_DOMAINE}"
    openssl x509 -req -in ${DOSSIER_SSL_HTTPD}/${NOM_DOMAINE}.csr -CA ${DOSSIER_CRT_CA}/ca.crt -CAkey ${DOSSIER_CRT_CA}/ca.key \
    -CAcreateserial -out ${DOSSIER_SSL_HTTPD}/${NOM_DOMAINE}.crt -days 825 -sha256 \
    -extfile <(printf "basicConstraints=critical,CA:FALSE\nsubjectAltName=DNS:${NOM_DOMAINE},DNS:*.${NOM_DOMAINE}\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth")

    trust anchor ${DOSSIER_SSL_HTTPD}/${NOM_DOMAINE}.crt

    message "ok" "Création certificats SSL terminée"
}