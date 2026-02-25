#!/bin/bash

set -e

function creation_virtualhost 
{
    message "info" "Création du dossier ${DOSSIER_PUBLICATION}"
    mkdir -p ${DOSSIER_PUBLICATION}

    message "info" "Attribution des droits"
    chown -Rf ${UTILISATEUR}:apache ${DOSSIER_PUBLICATION}

    message "info" "Attribution des droits SELinux"
    chcon -Rt httpd_sys_rw_content_t ${DOSSIER_PUBLICATION}

    message "info" "Création fichier de configuration"
    tee "${DOSSIER_CFG_VHOSTS}/${NOM_VHOST}.conf" > /dev/null <<EOF
    <VirtualHost *:80>
        ServerName ${NOM_DOMAINE}
        Redirect permanent / https://${NOM_DOMAINE}/
    </VirtualHost>
EOF

    tee "${DOSSIER_CFG_VHOSTS}/${NOM_VHOST}-ssl.conf" > /dev/null <<EOF
    <VirtualHost *:443>
        ServerName ${NOM_DOMAINE}
        DocumentRoot ${DOSSIER_PUBLICATION}

        SSLEngine on
        SSLCertificateFile ${DOSSIER_SSL_HTTPD}/${NOM_DOMAINE}.crt
        SSLCertificateKeyFile ${DOSSIER_SSL_HTTPD}/${NOM_DOMAINE}.key

        <Directory ${DOSSIER_PUBLICATION}>
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog logs/${NOM_VHOST}-ssl-error.log
        CustomLog logs/${NOM_VHOST}-ssl-access.log combined
    </VirtualHost>
EOF
    message "info" "Ajout dans /etc/hosts"
    echo "127.0.0.1 ${NOM_DOMAINE}" | tee -a /etc/hosts > /dev/null

    message "info" "Redémarrage Apache"
    systemctl restart httpd

    msgbox "Opération terminée" "L'hôte virtuel ${NOM_VHOST} a bien été créé !" 20 60  

}

function suppression_virtualhost
{
    LISTE_VHOSTS=$(httpd -S 2>/dev/null | grep "namevhost" | grep -v "fe80" | awk '{print $4}' | sort | uniq)

    if [ -z "${LISTE_VHOSTS}" ]; then
        msgbox "Erreur" "Aucun hôte virtuel trouvé." 8 45
        exit 1
    fi

    options=()
    for vhost in ${LISTE_VHOSTS}; do
        options+=("$vhost" "")
    done

    NOM_DOMAINE=$(whiptail --title "Supprimer un hôte virtuel" \
                  --menu "Choisissez l'hôte virtuel à supprimer :" 20 60 10 \
                  "${options[@]}" \
                  3>&1 1>&2 2>&3)

    if [[ -z "${NOM_DOMAINE}" ]]; then
        msgbox "Erreur" "Il manque le nom de l'hôte virtuel"
    fi

    NOM_VHOST=$(echo "${NOM_DOMAINE}" | cut -d'.' -f1)

    DOSSIER_PUBLICATION=$(cat /etc/httpd/conf.d/${NOM_VHOST}-ssl.conf | grep DocumentRoot | awk '{print $2}')

    message "info" "Suppression dans /etc/hosts"
    sed -i "/${NOM_DOMAINE}/d" /etc/hosts

    message "info" "Suppression fichier de configuration"
    rm -f ${DOSSIER_CFG_VHOSTS}/${NOM_VHOST}*

    message "info" "Suppression certificats SSL"
    rm -f ${DOSSIER_SSL_HTTPD}/${NOM_VHOST}*
    rm -f /etc/pki/ca-trust/source/${NOM_VHOST}*

    message "info" "Suppression dossier ${DOSSIER_PUBLICATION}"
    rm -vRf ${DOSSIER_PUBLICATION}

    msgbox "Opération terminée" "L'hôte virtuel ${NOM_VHOST} a bien été supprimé"

}