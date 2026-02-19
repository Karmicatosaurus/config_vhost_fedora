# Setting up a virtual host with Apache on Fedora

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
