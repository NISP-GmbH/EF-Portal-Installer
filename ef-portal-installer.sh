#!/bin/bash

# variables
EF_PORTAL_JAR_URL="https://ni-sp.com/wp-content/uploads/2019/10/efportal-latest.jar"
EF_PORTAL_JAR_NAME=$(basename $EF_PORTAL_JAR_URL)
EF_PORTAL_CONFIG_URL="https://www.ni-sp.com/wp-content/uploads/2019/10/EFP-Download/efinstall.config"
EF_PORTAL_CONFIG_NAME=$(basename $EF_PORTAL_CONFIG_URL)
EF_PORTAL_SLURM_SUPPORT="false"
EF_PORTAL_DCVSM_SUPPORT="false"
EF_PORTAL_EFADMIN_USER="efadmin"
EF_PORTAL_EFADMIN_PASSWORD=$(echo "efadmin@#@$(printf '%04d' $((RANDOM % 10000)))")
EF_PORTAL_LICENSE_FILE=""
EF_PORTAL_HTTPS_PORT="8443"
JAVA_FILE_URL="https://www.ni-sp.com/wp-content/uploads/2019/10/jdk-11.0.19_linux-x64_bin.tar.gz"
JAVA_FILE_NAME=$(basename $JAVA_FILE_URL)

checkParameters()
{
    for arg in "$@"
    do
        case $arg in
            --slurm_support=true)
                EF_PORTAL_SLURM_SUPPORT="true"
                shift
                ;;
            --dcvsm_support=true)
                EF_PORTAL_DCVSM_SUPPORT="true"
                shift
                ;;
            --license_file=*)
                EF_PORTAL_LICENSE_FILE="${arg#--license_file=}"
                shift
                ;;
            --https_port=*)
                EF_PORTAL_HTTPS_PORT="${arg#--https_port=}"
                shift
                ;;
        esac
    done

    if ! $EF_PORTAL_SLURM_SUPPORT && ! $EF_PORTAL_DCVSM_SUPPORT
    then
        echo "You need to enable DCV SM or SLURM to setup. Exiting..."
        exit 6
    fi

    if [[ "${EF_PORTAL_LICENSE_FILE}x" == "x" ]]
    then
        echo "You need to provide the parameter >>> \$-license_file= <<<. Exiting..."
        exit 7
    fi 

    if [ ! -f $EF_PORTAL_LICENSE_FILE ]
    then
        echo "The file >>> $EF_PORTAL_LICENSE_FILE <<< was not found. You need to specify an existing file for the license. Exiting..."
        exit 8
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

    if cat /etc/os-release | egrep -iq "(ubuntu|debian)"
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

    wget --quiet --no-check-certificate $EF_PORTAL_JAR_URL
    [ $? -ne 0 ] && echo "Failed to download >>> ${EF_PORTAL_JAR_NAME} <<<. Exiting..." && exit 3

    wget --quiet --no-check-certificate $EF_PORTAL_CONFIG_URL
    [ $? -ne 0 ] && echo "Failed to download >>> ${EF_PORTAL_CONFIG_NAME} <<<. Exiting..." && exit 4

    sed -i "s/kernel.tomcat.https.port.*=.*/kernel.tomcat.https.port = $EF_PORTAL_HTTPS_PORT/" ${EF_PORTAL_CONFIG_NAME}

    if cat /etc/os-release | egrep -iq "(ubuntu|debian)"
    then
        sed -i 's/system-auth/common-auth/' ${EF_PORTAL_CONFIG_NAME}
    fi

    sudo bash -c "export JAVA_HOME=/usr/local/jdk-11.0.19 && export PATH=\$JAVA_HOME/bin:\$PATH && umask 022 && java -jar ${EF_PORTAL_JAR_NAME} --batch -f ${EF_PORTAL_CONFIG_NAME}"
    sudo systemctl enable --now enginframe.service

    rm -f $EF_PORTAL_JAR_NAME $EF_PORTAL_CONFIG_NAME
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
