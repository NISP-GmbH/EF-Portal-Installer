# EF-Portal-Installer

A script to setup EF Portal without interactions.

Supported Linux distributions:

* Ubuntu based: 20.04, 22.04 and 24.04.
* RedHat based: 8 and 9.

## How to setup with SLURM configured:

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --slurm_support=true --license_file=./license.ef
```

## How to setup with DCV SM configured:

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --dcvsm_support=true --license_file=./license.ef

```
