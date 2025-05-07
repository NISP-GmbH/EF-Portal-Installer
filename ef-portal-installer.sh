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

EF_PORTAL_SLURM_SUPPORT="false"
EF_PORTAL_DCVSM_SUPPORT="false"
EF_PORTAL_EFADMIN_USER="efadmin"
EF_PORTAL_EFADMIN_PASSWORD=$(echo "efadmin@#@$(printf '%04d' $((RANDOM % 10000)))")
EF_PORTAL_LICENSE_FILE=""
EF_PORTAL_HTTPS_PORT="8443"
EF_PORTAL_SILENT_SETUP="false"
JAVA_FILE_URL="https://www.ni-sp.com/wp-content/uploads/2019/10/jdk-11.0.19_linux-x64_bin.tar.gz"
JAVA_FILE_NAME=$(basename $JAVA_FILE_URL)

commandExists()
{
    command -v "$1" &> /dev/null
}

printMessage()
{
	if ! $EF_PORTAL_SILENT_SETUP
	then
		echo $@
	fi
}

checkParameters()
{
	printMessage "Checking parameters..."
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
			--silent)
				EF_PORTAL_SILENT_SETUP= "true"
				shift
				;;
        esac
    done

    if [[ "${EF_PORTAL_LICENSE_FILE}x" == "x" ]]
    then
		printMessage "You need to provide the parameter >>> --license_file= <<<. Exiting..."
        exit 7
    fi 

    if [ ! -f $EF_PORTAL_LICENSE_FILE ]
    then
		printMessage "The file >>> $EF_PORTAL_LICENSE_FILE <<< was not found. You need to specify an existing file for the license. Exiting..."
        exit 8
    fi
}

# Setup environment
prepareEnvironment()
{
	printMessage "Preparing the environment..."
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

	printMessage "Installing needed packages..."
	if commandExists apt
	then
        sudo apt update -y
        sudo apt install unzip tar -y
	fi
    
	if commandExists yum
	then
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
    
	printMessage "Downloading Java..."
    wget --quiet --no-check-certificate $JAVA_FILE_URL
    [ $? -ne 0 ] && printMessage "Failed to download >>> ${JAVA_FILE_NAME} <<<. Exiting..." && exit 1

	printMessage "Extracting Java..."
    sudo tar zxf $JAVA_FILE_NAME -C /usr/local/
    [ $? -ne 0 ] && printMessage "Failed to extract >>> ${JAVA_FILE_NAME} <<<. Exiting..." && exit 2
    rm -f $JAVA_FILE_NAME


	printMessage "Creating users..."
    sudo bash -c "useradd -m ${EF_PORTAL_EFADMIN_USER} && useradd -m efnobody"
    echo -e "${EF_PORTAL_EFADMIN_PASSWORD}\n${EF_PORTAL_EFADMIN_PASSWORD}" | sudo passwd ${EF_PORTAL_EFADMIN_USER}

    if [ ! -f ${EF_PORTAL_JAR_NAME} ]
    then
		printMessage "Downloading EF Portal jar file..."
        wget --quiet --no-check-certificate $EF_PORTAL_JAR_URL
        [ $? -ne 0 ] && printMessage "Failed to download >>> ${EF_PORTAL_JAR_NAME} <<<. Exiting..." && exit 3
    fi

    if [ ! -f ${EF_PORTAL_CONFIG_NAME} ]
    then
		printMessage "Downloading EF Portal config file..."
        wget --quiet --no-check-certificate $EF_PORTAL_CONFIG_URL
        [ $? -ne 0 ] && printMessage "Failed to download >>> ${EF_PORTAL_CONFIG_NAME} <<<. Exiting..." && exit 4
    fi

	printMessage "Configuring EF Portal..."
    sed -i "s/kernel.tomcat.https.port.*=.*/kernel.tomcat.https.port = $EF_PORTAL_HTTPS_PORT/" ${EF_PORTAL_CONFIG_NAME}

    # if slurm and dcvsm will ne enabled
    if $EF_PORTAL_SLURM_SUPPORT && $EF_PORTAL_DCVSM_SUPPORT
    then
       # if dcvsm and slurm
       sed -i "s/ef.jobmanager.*=.*/ef.jobmanager = dcvsm,slurm/" ${EF_PORTAL_CONFIG_NAME}
    elif $EF_PORTAL_SLURM_SUPPORT && ! $EF_PORTAL_DCVSM_SUPPORT
    then
       # if just slurm
       sed -i "s/ef.jobmanager.*=.*/ef.jobmanager = slurm/" ${EF_PORTAL_CONFIG_NAME}
    elif ! $EF_PORTAL_SLURM_SUPPORT && $EF_PORTAL_DCVSM_SUPPORT
    then
       # if just dcvsm
       sed -i "s/ef.jobmanager.*=.*/ef.jobmanager = dcvsm/" ${EF_PORTAL_CONFIG_NAME}
    else
       # if nothing
       sed -i "s/ef.jobmanager.*=.*/#ef.jobmanager = /" ${EF_PORTAL_CONFIG_NAME}
    fi
    
    if cat /etc/os-release | egrep -iq "(ubuntu|debian)"
    then
        sed -i 's/system-auth/common-auth/' ${EF_PORTAL_CONFIG_NAME}
    fi

	printMessage "Installing EF Portal..."
    sudo bash -c "export JAVA_HOME=/usr/local/jdk-11.0.19 && export PATH=\$JAVA_HOME/bin:\$PATH && umask 022 && java -jar ${EF_PORTAL_JAR_NAME} --batch -f ${EF_PORTAL_CONFIG_NAME}"

    return_code=$?
    [ $return_code -ne 0 ] && printMessage "Failed to setup EF Portal. The exit error was >>> $return_code <<<. Exiting..." && exit 6
    
	printMessage "Enabling and starting enginframe systemd service..."
    sudo systemctl enable --now enginframe.service

    rm -f $EF_PORTAL_JAR_NAME $EF_PORTAL_CONFIG_NAME
}

printPassword()
{
	printMessage "User: ${EF_PORTAL_EFADMIN_USER}"
	printMessage "Password: ${EF_PORTAL_EFADMIN_PASSWORD}"
}

finishMessage()
{
	printMessage "EF Portal url: https://your_ip:8443"
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
printMessage "Unknown error. Exitting..."
exit 255
