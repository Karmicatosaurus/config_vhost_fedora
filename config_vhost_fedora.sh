#!/bin/bash

set -e

function menu_demarrage() {
    CHOIX=$(whiptail --title "Config VHOST" --menu "Que voulez vous faire ?" 12 40 5 "ajout" "Ajouter un projet" "supprime" "Supprimer un projet" "Quitter" "Quitter"  3>&1 1>&2 2>&3)

    case "$CHOIX" in
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

function message() {
    whiptail --title "Config VHOST" --msgbox "$1" 8 40
    menu_demarrage
}

function creation_certificat_ssl() {

    DOSSIER_CRT_CA="/home/${UTILISATEUR}/.local/share/HttpCerts"
    CN_CA=""
    O_CA=""

    if [[ ! -d "${DOSSIER_CRT_CA}" ]]; then
        mkdir -p ${DOSSIER_CRT_CA}
        openssl genrsa -out ${DOSSIER_CRT_CA}/ca.key 4096
        openssl req -x509 -new -nodes -key ${DOSSIER_SRV}/ca.key -sha256 -days 3650 \
        -out ${DOSSIER_SRV}/ca.crt \
        -subj "/CN=${CN_CA}/O=${O_CA}" \
        -addext "basicConstraints=critical,CA:TRUE" \
        -addext "keyUsage=critical,keyCertSign,cRLSign"
    fi

    if [[ ! -d "${DOSSIER_CRT_SSL}" ]]; then
        mkdir -p ${DOSSIER_CRT_SSL}
    fi

    openssl genrsa -out ${DOSSIER_CRT_SSL}/${NOM_DOMAINE}.key 4096
    openssl req -new -key ${DOSSIER_CRT_SSL}/${NOM_DOMAINE}.key  -out ${DOSSIER_CRT_SSL}/${NOM_DOMAINE}.csr -subj "/CN=${NOM_DOMAINE}"
    openssl x509 -req -in ${DOSSIER_CRT_SSL}/${NOM_DOMAINE}.csr -CA ${DOSSIER_CRT_CA}/ca.crt -CAkey ${DOSSIER_CRT_CA}/ca.key \
    -CAcreateserial -out ${DOSSIER_CRT_SSL}/${NOM_DOMAINE}.crt -days 825 -sha256 \
    -extfile <(printf "basicConstraints=critical,CA:FALSE\nsubjectAltName=DNS:${NOM_DOMAINE},DNS:*.${NOM_DOMAINE}\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth")

    trust anchor ${DOSSIER_CRT_SSL}/${NOM_DOMAINE}.crt
}

function creation_projet() {

    mkdir -p ${DOSSIER_PUBLICATION}

    chown -Rf "${UTILISATEUR}":apache "${DOSSIER_PUBLICATION}"
    chcon -Rt httpd_sys_rw_content_t "${DOSSIER_PUBLICATION}"

    tee "${DOSSIER_CFG_HTTPD}/conf.d/${NOM_PROJET}.conf" > /dev/null <<EOF
    <VirtualHost *:80>
        ServerName ${NOM_DOMAINE}
        Redirect permanent / https://${NOM_DOMAINE}/
    </VirtualHost>
EOF

    tee "${DOSSIER_CFG_HTTPD}/conf.d/${NOM_PROJET}-ssl.conf" > /dev/null <<EOF
    <VirtualHost *:443>
        ServerName ${NOM_DOMAINE}
        DocumentRoot ${DOSSIER_PUBLICATION}

        SSLEngine on
        SSLCertificateFile ${DOSSIER_CRT_SSL}/${NOM_DOMAINE}.crt
        SSLCertificateKeyFile ${DOSSIER_CRT_SSL}/${NOM_DOMAINE}.key

        <Directory ${DOSSIER_PUBLICATION}>
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog logs/${NOM_PROJET}-ssl-error.log
        CustomLog logs/${NOM_PROJET}-ssl-access.log combined
    </VirtualHost>
EOF

    echo "127.0.0.1 ${NOM_DOMAINE}" | tee -a /etc/hosts > /dev/null

    systemctl restart httpd

}

function supprime_projet {

    LISTE_VHOSTS=$(httpd -S 2>/dev/null | grep "namevhost" | grep -v "fe80" | awk '{print $4}' | sort | uniq)

    if [ -z "LISTE_VHOSTS" ]; then
        whiptail --title "Erreur" --msgbox "Aucun projet trouvé." 8 45
        exit 1
    fi

    options=()
    for vhost in LISTE_VHOSTS; do
        options+=("$vhost" "")
    done

    NOM_DOMAINE=$(whiptail --title "Supprimer un projet" \
                  --menu "Choisissez le projet à supprimer :" 20 60 10 \
                  "${options[@]}" \
                  3>&1 1>&2 2>&3)

    if [[ -z "${NOM_DOMAINE}" ]]; then
        message "Il manque le nom du projet"
    fi

    NOM_PROJET=$(echo "${NOM_DOMAINE}" | cut -d'.' -f1)

    DOSSIER_PUBLICATION=$(cat /etc/httpd/conf.d/${NOM_PROJET}-ssl.conf | grep DocumentRoot | awk '{print $2}')

    sed -i "/${NOM_DOMAINE}/d" /etc/hosts
    rm -f /etc/httpd/conf.d/${NOM_PROJET}*
    rm -f /etc/httpd/ssl/${NOM_PROJET}*
    rm -f /etc/pki/ca-trust/source/${NOM_PROJET}*
    rm -vRf ${DOSSIER_PUBLICATION}

    message "Le projet ${NOM_PROJET} a bien été supprimé"
}

AJOUT=false
SUPPRIME=false

UTILISATEUR="$SUDO_USER"
DOSSIER_CFG_HTTPD="/etc/httpd"
DOSSIER_CRT_SSL=${DOSSIER_CFG_HTTPD} . "/ssl"

DOSSIER_RACINE="/web/pub"
TLD_PROJET="dev"
NOM_DOMAINE=""
DOSSIER_PUBLICATION=""

menu_demarrage

if [ "$AJOUT" == "true" ]; then

    NOM_PROJET=$(whiptail --title "Config VHOST" --inputbox "Nom du projet" 8 40 3>&1 1>&2 2>&3)

    if [[ -z "$PROJECT_NAME" ]]; then
        message "Il manque le nom du projet"
    fi

    TLD_PROJET=$(whiptail --title "Config VHOST" --inputbox "TLD du projet" 8 40 ${TLD_PROJET} 3>&1 1>&2 2>&3)

    if [[ -z "$TLD_PROJET" ]]; then
        message "Il manque le TLD du projet"
    fi

    DOSSIER_RACINE=$(whiptail --title "Config VHOST" --inputbox "Dossier racine" 8 40 ${DOSSIER_RACINE} 3>&1 1>&2 2>&3)

    if [[ -z "$DOSSIER_RACINE" ]]; then
        message "Il manque le dossier racine"
    fi

    DOSSIER_RACINE="${DOSSIER_RACINE%/}"
    TLD_PROJET="${TLD_PROJET/#./}"

    NOM_DOMAINE=${NOM_PROJET}.${TLD_PROJET}
    DOSSIER_PUBLICATION=${DOSSIER_RACINE}.${NOM_PROJET}

    if httpd -S 2>/dev/null | grep -q "namevhost ${PROJECT_NAME}"; then
        message "Le projet existe déjà"
    fi

    if [[ -d "${DOSSIER_PUBLICATION}" ]]; then
        message "Le dossier du projet existe déjà"
    fi

    creation_certificat_ssl

    creation_projet

elif [ "$SUPPRIME" == "true" ]; then

    supprime_projet
fi

menu_demarrage
