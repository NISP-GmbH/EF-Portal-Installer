#!/bin/bash

# variables
EF_PORTAL_JAR_URL="https://ni-sp.com/wp-content/uploads/2019/10/efportal-latest.jar"

if [[ "${EF_PORTAL_JAR_NAME}x" == "x" ]]
then
    EF_PORTAL_JAR_NAME=$(basename $EF_PORTAL_JAR_URL)
fi

EF_PORTAL_CONFIG_URL="https://www.ni-sp.com/wp-content/uploads/2019/10/EFP-Download/efinstall.config"

if [[ "${EF_PORTAL_CONFIG_NAME}x" == "x" ]]
then 
    EF_PORTAL_CONFIG_NAME=$(basename $EF_PORTAL_CONFIG_URL)
fi

EF_PORTAL_JAR_FILE=""
EF_PORTAL_JAR_DOWNLOADED="false"
EF_PORTAL_SLURM_SUPPORT="false"
EF_PORTAL_DCVSM_SUPPORT="false"
EF_PORTAL_EFADMIN_USER="efadmin"
EF_PORTAL_EFADMIN_PASSWORD=$(echo "efadmin@#@$(printf '%04d' $((RANDOM % 10000)))")
EF_PORTAL_LICENSE_FILE=""
EF_PORTAL_LICENSE_DEFAULT_NAME="license.ef"
EF_PORTAL_HTTPS_PORT="8443"
EF_PORTAL_START_AT_BOOT="true"
JAVA_FILE_URL="https://www.ni-sp.com/wp-content/uploads/2019/10/jdk-11.0.19_linux-x64_bin.tar.gz"
JAVA_FILE_NAME=$(basename $JAVA_FILE_URL)

showHelp()
{
    cat <<EOF
Usage: ef-portal-installer.sh [--license_file=<path>] [options]

A script to setup EF Portal without interactions.

License (required, as a parameter or as a file):

  --license_file=<path>            Absolut path of the EF Portal license file (license.ef).
                                   Optional when a ${EF_PORTAL_LICENSE_DEFAULT_NAME} file is present in the current
                                   directory or next to this script, which is then used.

Optional parameters:

  --jar_file=<path>                Use a local EF Portal .jar file instead of downloading it
                                   from ${EF_PORTAL_JAR_URL}
                                   The file is kept after the setup.
  --slurm_support=<b>              Enable slurm as jobmanager during setup.
                                   Values: true or false. (default: ${EF_PORTAL_SLURM_SUPPORT})
  --dcvsm_support=<b>              Enable dcvsm as jobmanager during setup.
                                   Values: true or false. (default: ${EF_PORTAL_DCVSM_SUPPORT})
  --https_port=<port>              Customize the web gui https port. (default: ${EF_PORTAL_HTTPS_PORT})
  --start-enginframe-at-boot=<b>   Control whether EnginFrame starts at boot.
                                   Values: true or false. (default: ${EF_PORTAL_START_AT_BOOT})
  -h, --help                       Show this help message and exit.

Examples:

  # setup without any job manager
  ef-portal-installer.sh --license_file=./license.ef

  # same, using the license.ef file found in the current directory
  ef-portal-installer.sh

  # setup with slurm and dcvsm as job managers
  ef-portal-installer.sh --license_file=./license.ef --slurm_support=true --dcvsm_support=true

  # setup using a local .jar file
  ef-portal-installer.sh --license_file=./license.ef --jar_file=./efportal-latest.jar
EOF
    exit 0
}

checkParameters()
{
    for arg in "$@"
    do
        case $arg in
            -h|--help)
                showHelp
                ;;
            --slurm_support=*)
                EF_PORTAL_SLURM_SUPPORT="${arg#--slurm_support=}"
                shift
                ;;
            --dcvsm_support=*)
                EF_PORTAL_DCVSM_SUPPORT="${arg#--dcvsm_support=}"
                shift
                ;;
            --license_file=*)
                EF_PORTAL_LICENSE_FILE="${arg#--license_file=}"
                shift
                ;;
            --jar_file=*)
                EF_PORTAL_JAR_FILE="${arg#--jar_file=}"
                EF_PORTAL_JAR_NAME="${EF_PORTAL_JAR_FILE}"
                shift
                ;;
            --https_port=*)
                EF_PORTAL_HTTPS_PORT="${arg#--https_port=}"
                shift
                ;;
            --start-enginframe-at-boot=*)
                EF_PORTAL_START_AT_BOOT="${arg#--start-enginframe-at-boot=}"
                shift
                ;;
        esac
    done

    # if no license file was given, look for license.ef in the current directory
    # and then in the directory where this script is located
    if [[ "${EF_PORTAL_LICENSE_FILE}x" == "x" ]]
    then
        if [ -f "./${EF_PORTAL_LICENSE_DEFAULT_NAME}" ]
        then
            EF_PORTAL_LICENSE_FILE="./${EF_PORTAL_LICENSE_DEFAULT_NAME}"
        elif [ -f "${BASH_SOURCE[0]}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/${EF_PORTAL_LICENSE_DEFAULT_NAME}" ]
        then
            EF_PORTAL_LICENSE_FILE="$(dirname "${BASH_SOURCE[0]}")/${EF_PORTAL_LICENSE_DEFAULT_NAME}"
        fi

        if [[ "${EF_PORTAL_LICENSE_FILE}x" != "x" ]]
        then
            echo "The parameter >>> --license_file= <<< was not provided. Using the license file found in >>> ${EF_PORTAL_LICENSE_FILE} <<<."
        fi
    fi

    if [[ "${EF_PORTAL_LICENSE_FILE}x" == "x" ]]
    then
        echo "You need to provide the parameter >>> --license_file= <<< or leave the >>> ${EF_PORTAL_LICENSE_DEFAULT_NAME} <<< file in the current directory. Exiting..."
        exit 7
    fi 

    if [ ! -f $EF_PORTAL_LICENSE_FILE ]
    then
        echo "The file >>> $EF_PORTAL_LICENSE_FILE <<< was not found. You need to specify an existing file for the license. Exiting..."
        exit 8
    fi

    if [[ "${EF_PORTAL_JAR_FILE}x" != "x" ]] && [ ! -f "$EF_PORTAL_JAR_FILE" ]
    then
        echo "The file >>> $EF_PORTAL_JAR_FILE <<< was not found. You need to specify an existing .jar file. Exiting..."
        exit 10
    fi

    # Validate --start-enginframe-at-boot parameter
    if [[ "${EF_PORTAL_START_AT_BOOT}" != "true" && "${EF_PORTAL_START_AT_BOOT}" != "false" ]]
    then
        echo "Invalid value for --start-enginframe-at-boot=. Must be 'true' or 'false'. Exiting..."
        exit 9
    fi

    # Validate --slurm_support parameter
    if [[ "${EF_PORTAL_SLURM_SUPPORT}" != "true" && "${EF_PORTAL_SLURM_SUPPORT}" != "false" ]]
    then
        echo "Invalid value for --slurm_support=. Must be 'true' or 'false'. Exiting..."
        exit 11
    fi

    # Validate --dcvsm_support parameter
    if [[ "${EF_PORTAL_DCVSM_SUPPORT}" != "true" && "${EF_PORTAL_DCVSM_SUPPORT}" != "false" ]]
    then
        echo "Invalid value for --dcvsm_support=. Must be 'true' or 'false'. Exiting..."
        exit 12
    fi
}

# Setup environment
prepareEnvironment()
{
    cat <<EOF >> ~/.bashrc 
alias p=pushd
alias l="ls -ltr"
alias x="emacs -nw "
alias ex=exit
alias les=less
alias j=jobs
alias m=less
export PATH=\$PATH:.
export JAVA_HOME=/usr/local/jdk-11.0.19
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
    source ~/.bashrc

    if cat /etc/os-release | grep -Eiq "(ubuntu|debian)"
    then
        sudo apt update -y
        sudo apt install unzip tar -y
    else
        sudo yum install emacs-nox unzip tar -y
    fi
}

# Download and install EF Portal
setupEfportal()
{
    if [ -f $JAVA_FILE_NAME ]
    then
        rm -f $JAVA_FILE_NAME
    fi
    
    wget --quiet --no-check-certificate $JAVA_FILE_URL
    [ $? -ne 0 ] && echo "Failed to download >>> ${JAVA_FILE_NAME} <<<. Exiting..." && exit 1

    sudo tar zxf $JAVA_FILE_NAME -C /usr/local/
    [ $? -ne 0 ] && echo "Failed to extract >>> ${JAVA_FILE_NAME} <<<. Exiting..." && exit 2
    rm -f $JAVA_FILE_NAME

    sudo bash -c "useradd -m ${EF_PORTAL_EFADMIN_USER} && useradd -m efnobody && rm -rf /opt/nisp/enginframe"
    echo -e "${EF_PORTAL_EFADMIN_PASSWORD}\n${EF_PORTAL_EFADMIN_PASSWORD}" | sudo passwd ${EF_PORTAL_EFADMIN_USER}

    if [ ! -f ${EF_PORTAL_JAR_NAME} ]
    then
        wget --quiet --no-check-certificate $EF_PORTAL_JAR_URL
        [ $? -ne 0 ] && echo "Failed to download >>> ${EF_PORTAL_JAR_NAME} <<<. Exiting..." && exit 3
        EF_PORTAL_JAR_DOWNLOADED="true"
    fi

    if [ ! -f ${EF_PORTAL_CONFIG_NAME} ]
    then
        wget --quiet --no-check-certificate $EF_PORTAL_CONFIG_URL
        [ $? -ne 0 ] && echo "Failed to download >>> ${EF_PORTAL_CONFIG_NAME} <<<. Exiting..." && exit 4
    fi

    sed -i "s/kernel.tomcat.https.port.*=.*/kernel.tomcat.https.port = $EF_PORTAL_HTTPS_PORT/" ${EF_PORTAL_CONFIG_NAME}

    # if slurm and dcvsm will ne enabled
    # the config file ships with >>> ef.jobmanager = dcvsm,slurm <<<, so the line
    # has to be commented out when no job manager was asked for
    if [[ "${EF_PORTAL_SLURM_SUPPORT}" == "true" && "${EF_PORTAL_DCVSM_SUPPORT}" == "true" ]]
    then
       # if dcvsm and slurm
       sed -i "s/^#*ef\.jobmanager[[:space:]]*=.*/ef.jobmanager = dcvsm,slurm/" ${EF_PORTAL_CONFIG_NAME}
    elif [[ "${EF_PORTAL_SLURM_SUPPORT}" == "true" && "${EF_PORTAL_DCVSM_SUPPORT}" != "true" ]]
    then
       # if just slurm
       sed -i "s/^#*ef\.jobmanager[[:space:]]*=.*/ef.jobmanager = slurm/" ${EF_PORTAL_CONFIG_NAME}
    elif [[ "${EF_PORTAL_SLURM_SUPPORT}" != "true" && "${EF_PORTAL_DCVSM_SUPPORT}" == "true" ]]
    then
       # if just dcvsm
       sed -i "s/^#*ef\.jobmanager[[:space:]]*=.*/ef.jobmanager = dcvsm/" ${EF_PORTAL_CONFIG_NAME}
    else
       # if nothing
       sed -i "s/^#*ef\.jobmanager[[:space:]]*=.*/#ef.jobmanager = /" ${EF_PORTAL_CONFIG_NAME}
    fi
    
    if cat /etc/os-release | grep -Eiq "(ubuntu|debian)"
    then
        sed -i 's/system-auth/common-auth/' ${EF_PORTAL_CONFIG_NAME}
    fi

    # If start-enginframe-at-boot is false, update the config file
    if [[ "${EF_PORTAL_START_AT_BOOT}" == "false" ]]
    then
        sed -i 's/^start_enginframe_at_boot.*=.*/start_enginframe_at_boot = false/' ${EF_PORTAL_CONFIG_NAME}
    fi

    sudo bash -c "export JAVA_HOME=/usr/local/jdk-11.0.19 && export PATH=\$JAVA_HOME/bin:\$PATH && umask 022 && java -jar ${EF_PORTAL_JAR_NAME} --batch -f ${EF_PORTAL_CONFIG_NAME}"

    return_code=$?
    [ $return_code -ne 0 ] && echo "Failed to setup EF Portal. The exit error was >>> $return_code <<<. Exiting..." && exit 6
    
    sudo systemctl enable --now enginframe.service

    rm -f $EF_PORTAL_CONFIG_NAME

    # only remove the jar file when this script downloaded it
    if [[ "${EF_PORTAL_JAR_DOWNLOADED}" == "true" ]]
    then
        rm -f $EF_PORTAL_JAR_NAME
    fi
}

printPassword()
{
    echo "User: ${EF_PORTAL_EFADMIN_USER}"
    echo "Password: ${EF_PORTAL_EFADMIN_PASSWORD}"
}

finishMessage()
{
    echo "EF Portal url: https://your_ip:8443"
}

# main
main()
{
    prepareEnvironment
    setupEfportal
    printPassword
    finishMessage
    exit 0
}

checkParameters $@
main

# unknown error
echo "Unknown error. Exiting..."
exit 255
