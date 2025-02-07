# EF-Portal-Installer

A script to setup EF Portal without interactions.

Supported Linux distributions:

* Ubuntu based: 20.04, 22.04 and 24.04.
* RedHat based: 8 and 9.

# Requirements to execute

You need to provide the license.ef file (EF Portal license) to the parameter --license_file=.

Please provide the absolut path. Examples:


```bash
# if is in the same directory
--license_file=./license.ef
# or inside of root
--license_file=/root/license.ef
```

## Parameters:

* --license_file= : Absolut path of license file
* --slurm_support=true : enable slurm as jobmaneger during setup
* --dcvsm_support=true : enable dcvsm as jobmanager during setup
* --https_port= : customize the web gui https port

# Execution examples

## How to setup...

### without any job manager

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --license_file=./license.ef
```

### SLURM configured as job manager

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --slurm_support=true --license_file=./license.ef
```

### DCV SM configured as job manager

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --dcvsm_support=true --license_file=./license.ef

```

### DCV SM and SLURM as job managers

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --dcvsm_support=true --slurm_support=true --license_file=./license.ef
```

## How to customize the web gui https port

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --license_file=./license.ef --https_port=8448
```
