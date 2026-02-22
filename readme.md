# Setting up a virtual host with Apache on Fedora

### Add Virtualhost

![Menu principal](http://dev.karmicat.fr/artsys/images/vhost_menu.png)

![Nom du projet](http://dev.karmicat.fr/artsys/images/vhost_ajout_nom.png)

![TLD du projet](http://dev.karmicat.fr/artsys/images/vhost_ajout_tld.png)

![Dossier du projet](http://dev.karmicat.fr/artsys/images/vhost_ajout_dossier_pub.png)

![Récap création](http://dev.karmicat.fr/artsys/images/vhost_ajout_fin.png)

### Delete Virtualhost

![Choix suppression](http://dev.karmicat.fr/artsys/images/vhost_suppr_choix.png)

![Confirm suppression](http://dev.karmicat.fr/artsys/images/vhost_suppr_fin.png)

## 📌 Prerequisites

- **Operating System**: Fedora
- **Apache**: Installed and running (`sudo dnf install httpd`).
- **Permissions**: The script must be executed with `sudo` or as the `root` user.
- **Whiptail** (for TUI)

## 🚀 Installation

1) Install Whiptail

```bash
sudo dnf install newt
```

2) Clone Git

```bash
git clone https://github.com/Karmicatosaurus/config_vhost_fedora.git
cd config_vhost_fedora
chmod +x config_vhost_fedora.sh
```
