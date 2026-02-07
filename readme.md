# Setting up a virtual host with Apache on Fedora

## 📌 Prerequisites

- **Operating System**: Fedora
- **Apache**: Installed and running (`sudo dnf install httpd`).
- **Permissions**: The script must be executed with `sudo` or as the `root` user.

## 🚀 Installation

```bash
git clone https://github.com/Karmicatosaurus/config_vhost_fedora.git
cd config_vhost_fedora
chmod +x config_vhost_fedora.sh
```

## 🔧 Usage

```bash
sudo ./config_vhost_fedora.sh --project PROJECT --tld TLD --pubdir DIRECTORY
```

| Option | Description | Default Value |
| :----- | :--------- | :------------: |
| --project | Project name | |
| --tld     | TLD of project | local |
| --rootdir | Path of root directory | /var/www |