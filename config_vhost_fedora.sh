#!/bin/bash

set -e

function message() {
    whiptail --title "Config VHOST" --msgbox "$1" 8 40
    exit 1
}

AJOUT=false
SUPPRIME=false
USER="$SUDO_USER"
SSL_DIR="/etc/httpd/ssl"

CHOIX=$(whiptail --title "Config VHOST" --menu "Que voulez vous faire ?" 12 40 5 "ajout" "Ajouter un projet" "supprime" "Supprimer un projet" 3>&1 1>&2 2>&3)

case "$CHOIX" in
    "ajout")
        AJOUT=true
        ;;
    "supprime")
        SUPPRIME=true
        ;;
esac 

if [ "$AJOUT" == "true" ]; then

    ROOT_DIR="/var/www"

    PROJECT_NAME=$(whiptail --title "Config VHOST" --inputbox "Nom du projet" 8 40 3>&1 1>&2 2>&3)

    if [[ -z "$PROJECT_NAME" ]]; then
        message "Il manque le nom du projet"
    fi

    PROJECT_TLD=$(whiptail --title "Config VHOST" --inputbox "TLD" 8 40 local 3>&1 1>&2 2>&3)
    ROOT_DIR=$(whiptail --title "Config VHOST" --inputbox "Dossier de publication" 8 40 $ROOT_DIR 3>&1 1>&2 2>&3)

    ROOT_DIR="${ROOT_DIR%/}"
    PROJECT_TLD="${PROJECT_TLD/#./}"

    DOMAIN="$PROJECT_NAME.$PROJECT_TLD"
    PUB_DIR="$ROOT_DIR/$PROJECT_NAME"

    CONF_HTTP="/etc/httpd/conf.d/$PROJECT_NAME.conf"
    CONF_HTTPS="/etc/httpd/conf.d/$PROJECT_NAME-ssl.conf"
    CRT="$SSL_DIR/$DOMAIN.crt"
    KEY="$SSL_DIR/$DOMAIN.key"

    if httpd -S 2>/dev/null | grep -q "namevhost $DOMAIN"; then
        message "Le projet existe déjà"
    fi

    if [[ -d "$PUB_DIR" ]]; then
        message "Le dossier du projet existe déjà"
    fi

    mkdir -p "$PUB_DIR"
    chown -Rf "$USER":apache "$PUB_DIR"
    chcon -Rt httpd_sys_rw_content_t "$PUB_DIR"      

    if [[ ! -d "$SSL_DIR" ]]; then
    mkdir -p "$SSL_DIR"
    fi

    openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout "$KEY" -out "$CRT" -subj "/CN=$DOMAIN"

    trust anchor "$CRT"

    tee "$CONF_HTTP" > /dev/null <<EOF
    <VirtualHost *:80>
        ServerName $DOMAIN
        Redirect permanent / https://$DOMAIN/
    </VirtualHost>
EOF

    tee "$CONF_HTTPS" > /dev/null <<EOF
    <VirtualHost *:443>
        ServerName $DOMAIN
        DocumentRoot $PUB_DIR

        SSLEngine on
        SSLCertificateFile $CRT
        SSLCertificateKeyFile $KEY

        <Directory $PUB_DIR>
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog logs/$PROJECT-ssl-error.log
        CustomLog logs/$PROJECT-ssl-access.log combined
    </VirtualHost>
EOF

    echo "127.0.0.1 $DOMAIN" | tee -a /etc/hosts > /dev/null

    systemctl restart httpd

    whiptail --title "Config VHOST" --msgbox "Le projet $PROJECT_NAME a bien été créé !
    Dossier de publication : $PUB_DIR
    Accés HTTP : http://$DOMAIN
    Accés HTTPS : https://$DOMAIN
    Redirection HTTP → HTTPS activée" 11 60    

elif [ "$SUPPRIME" == "true" ]; then
   
    VHOSTS=$(httpd -S 2>/dev/null | grep "namevhost" | grep -v "fe80" | awk '{print $4}' | sort | uniq)

    if [ -z "VHOSTS" ]; then
        whiptail --title "Erreur" --msgbox "Aucun projet trouvé." 8 45
        exit 1
    fi    

    options=()
    for host in $VHOSTS; do
        options+=("$host" "")
    done

    PROJECT_NAME=$(whiptail --title "Menu des Vhosts Apache" \
                  --menu "Choisissez un domaine à gérer :" 20 60 10 \
                  "${options[@]}" \
                  3>&1 1>&2 2>&3)

    if [[ -z "$PROJECT_NAME" ]]; then
        message "Il manque le nom du projet"
    fi

    DOMAIN=$(echo "$PROJECT_NAME" | cut -d'.' -f1)

    PUB_DIR=$(cat /etc/httpd/conf.d/${DOMAIN}-ssl.conf | grep DocumentRoot | awk '{print $2}')

    sed -i "/${PROJECT_NAME}/d" /etc/hosts
    rm -f /etc/httpd/conf.d/${DOMAIN}*
    rm -f /etc/httpd/ssl/${DOMAIN}*
    rm -f /etc/pki/ca-trust/source/${DOMAIN}*
    rm -vRf $PUB_DIR

    message "Le projet ${DOMAIN} a bien été supprimé"
fi