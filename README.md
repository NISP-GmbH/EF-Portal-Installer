# EF-Portal-Installer

A script to setup EF Portal without interactions.

Supported Linux distributions:

* Ubuntu based: 20.04, 22.04 and 24.04.
* RedHat based: 8, 9 and 10.

# Requirements to execute

You need to provide the license.ef file (EF Portal license) to the parameter --license_file=.

Please provide the absolut path. Examples:


```bash
# if is in the same directory
--license_file=./license.ef
# or inside of root
--license_file=/root/license.ef
```

The parameter can be omitted when a file named `license.ef` is present in the directory where
you execute the script (or in the directory where the script itself is located). In that case
the script uses it automatically and tells you which file it picked.

## Parameters:

* --license_file= : Absolut path of license file. Can be omitted when a `license.ef` file is present in the current directory
* --slurm_support= : enable slurm as jobmaneger during setup (values: `true` or `false`, default: `false`)
* --dcvsm_support= : enable dcvsm as jobmanager during setup (values: `true` or `false`, default: `false`)
* --https_port= : customize the web gui https port
* --start-enginframe-at-boot= : control whether EnginFrame starts at boot (values: `true` or `false`, default: `true`)
* --jar_file= : use a local EF Portal .jar file instead of downloading it
* --help, -h : show the help message with all the parameters and exit

# Execution examples

## How to setup...

### without any job manager

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --license_file=./license.ef
```

### without any job manager, using the license.ef of the current directory

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh
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

## How to disable EnginFrame start at boot

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --license_file=./license.ef --start-enginframe-at-boot=false
```

## How to use a local .jar file

By default the EF Portal .jar file is downloaded from the NI-SP website. To install from a
.jar file that you already have, provide it to the parameter --jar_file=.

The path can be absolut or relative to the directory where you execute the script. A .jar file
provided this way is not removed after the setup.

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --license_file=./license.ef --jar_file=/root/efportal-latest.jar
```

## How to show the help message

```bash
sudo bash -c "$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh)" bash ef-portal-installer.sh --help
```
