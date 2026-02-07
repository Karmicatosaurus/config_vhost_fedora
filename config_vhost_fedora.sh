#!/bin/bash

set -e

PROJECT=""
TLD="local"
ROOTDIR="/var/www"

function usage() {
    echo ""
    echo "Usage : sudo $0 --project PROJECT --tld TLD --pubdir DIRECTORY --composer"
    echo " --project    Project name"
    echo " --tld        TLD of project (if not specified : $DOMAIN)"
    echo " --rootdir    Path of root directory (if not specified : $ROOTDIR)"
    echo ""
    echo "Please note that this script must be run with sudo."
    echo ""
    exit 1
}

function message() {
    case "$1" in
        "info")
            echo "[INFO] $2"
            shift 2
            ;;
        "ok")
            printf "\033[32m[OK] $2 !\033[0m\n"
            shift 2
            ;;
        "error")
            printf "\033[31m[ERROR] $2 !\033[0m\n"
            exit 1
            ;;
        *)
            echo "Option unknow : $1"
            exit 1
            ;;
    esac    
}

if [ -z "$1" ]; then
  usage
fi

if [[ $EUID -ne 0 ]]; then
    message "error" "This script must be run with sudo"
fi

if ! grep -q "^ID=fedora$" /etc/os-release; then
    message "error" "This distribution is not Fedora"
fi

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --project)
        PROJECT="$2"
        shift 2
        ;;
    --tld)
        TLD="$2"
        shift 2
        ;;
    --rootdir)
        ROOTDIR="$2"
        ;;
    *)
      echo "Option unknow : $1"
      exit 1
      ;;
    esac
done

if [[ -z "$PROJECT" ]]; then
  usage
fi

ROOTDIR="${ROOTDIR%/}"
TLD="${TLD/#./}"

DOMAIN="$PROJECT.$TLD"
PUBDIR="$ROOTDIR/$PROJECT"
USER="$SUDO_USER"

CONF_HTTP="/etc/httpd/conf.d/$PROJECT.conf"
CONF_SSL="/etc/httpd/conf.d/$PROJECT-ssl.conf"
SSL_DIR="/etc/httpd/ssl"
CRT="$SSL_DIR/$DOMAIN.crt"
KEY="$SSL_DIR/$DOMAIN.key"

if httpd -S 2>/dev/null | grep -q "namevhost $DOMAIN"; then
    message "error" "The project already exist"
fi

if [[ -d "$PUBDIR" ]]; then
    message "error" "The directory already exist"
fi

message "info" "Creating directory"
mkdir -p "$PUBDIR"
chown -Rf "$USER":apache "$PUBDIR"
chcon -Rt httpd_sys_rw_content_t "$PUBDIR"
message "ok" "Directory created"

message "info" "Creating SSL"
if [[ ! -d "$SSL_DIR" ]]; then
  mkdir -p "$SSL_DIR"
fi

openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout "$KEY" -out "$CRT" -subj "/CN=$DOMAIN"

trust anchor "$CRT"

message "ok" "SSL created"

message "info" "Creating VHOST"

tee "$CONF_HTTP" > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    Redirect permanent / https://$DOMAIN/
</VirtualHost>
EOF

tee "$CONF_SSL" > /dev/null <<EOF
<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot $PUBDIR

    SSLEngine on
    SSLCertificateFile $CRT
    SSLCertificateKeyFile $KEY

    <Directory $PUBDIR>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog logs/$PROJECT-ssl-error.log
    CustomLog logs/$PROJECT-ssl-access.log combined
</VirtualHost>
EOF

message "ok" "VHOST created"

message "info" "Add project in /etc/hosts"
echo "127.0.0.1 $DOMAIN" | tee -a /etc/hosts > /dev/null
message "ok" "Project added in /etc/hosts"

message "info" "Apache server restart"
systemctl restart httpd
message "ok" "Apache server restarted"

echo "------------------------------------------"
echo -e "\n\033[32mProject \"$PROJECT\" created with success !\033[0m"
echo "Directory : $PUBDIR"
echo "HTTP access : http://$DOMAIN"
echo "HTTPS access : https://$DOMAIN"
echo "HTTP → HTTPS redirection enabled"
echo "------------------------------------------"
