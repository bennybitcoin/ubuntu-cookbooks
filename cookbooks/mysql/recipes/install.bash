#!/bin/bash -e

function installDependencies()
{
    installAptGetPackages 'libaio-dev' 'sysv-rc-conf'
}

function install()
{
    # Clean Up

    initializeFolder "${mysqlInstallFolder}"
    rm -f -r "/usr/local/$(getFileName "${mysqlInstallFolder}")"

    # Install

    local currentPath="$(pwd)"

    unzipRemoteFile "${mysqlDownloadURL}" "${mysqlInstallFolder}"
    addUser "${mysqlUserName}" "${mysqlGroupName}" 'false' 'true' 'false'
    ln -s "${mysqlInstallFolder}" "/usr/local/$(getFileName "${mysqlInstallFolder}")"
    chown -R "${mysqlUserName}:${mysqlGroupName}" "${mysqlInstallFolder}"
    cd "${mysqlInstallFolder}"
    "${mysqlInstallFolder}/scripts/mysql_install_db" --user="${mysqlUserName}"
    chown -R "$(whoami)" "${mysqlInstallFolder}"
    chown -R "${mysqlUserName}" "${mysqlInstallFolder}/data"
    cd "${currentPath}"

    # Config Server

    local serverConfigData=('__PORT__' "${mysqlPort}")

    createFileFromTemplate "${appPath}/../templates/default/my.cnf.conf" "${mysqlInstallFolder}/my.cnf" "${serverConfigData[@]}"

    # Config Service

    cp -f "${mysqlInstallFolder}/support-files/mysql.server" "/etc/init.d/${mysqlServiceName}"
    sysv-rc-conf --level 2345 "${mysqlServiceName}" on

    # Config Profile

    local profileConfigData=('__INSTALL_FOLDER__' "${mysqlInstallFolder}")

    createFileFromTemplate "${appPath}/../templates/default/mysql.sh.profile" '/etc/profile.d/mysql.sh' "${profileConfigData[@]}"

    # Start

    service "${mysqlServiceName}" start

    # Run Secure Installation

    if [[ "${mysqlRunPostSecureInstallation}" = 'true' ]]
    then
        secureInstallation
    fi

    # Display Version

    info "\n\n$("${mysqlInstallFolder}/bin/mysql" --version)"
}

function secureInstallation()
{
    local secureInstaller="${mysqlInstallFolder}/bin/mysql_secure_installation"

    checkExistFile "${secureInstaller}"

    # Install Expect

    installAptGetPackages 'expect'

    # Config Option

    local setMySQLRootPassword='n'

    if [[ "${mysqlRootPassword}" != '' ]]
    then
        setMySQLRootPassword='Y'
    fi

    if [[ "${mysqlDeleteAnonymousUsers}" = 'true' ]]
    then
        mysqlDeleteAnonymousUsers='Y'
    else
        mysqlDeleteAnonymousUsers='n'
    fi

    if [[ "${mysqlDisallowRootLoginRemotely}" = 'true' ]]
    then
        mysqlDisallowRootLoginRemotely='Y'
    else
        mysqlDisallowRootLoginRemotely='n'
    fi

    if [[ "${mysqlDeleteTestDatabase}" = 'true' ]]
    then
        mysqlDeleteTestDatabase='Y'
    else
        mysqlDeleteTestDatabase='n'
    fi

    if [[ "${mysqlReloadPrivilegeTable}" = 'true' ]]
    then
        mysqlReloadPrivilegeTable='Y'
    else
        mysqlReloadPrivilegeTable='n'
    fi

    # Run Config

    cd "${mysqlInstallFolder}"

    expect << DONE
        set timeout 3
        spawn "${secureInstaller}"

        expect "Enter current password for root (enter for none): "
        send -- "\r"

        expect "Set root password? \[Y/n] "
        send -- "${setMySQLRootPassword}\r"

        if { "${setMySQLRootPassword}" == "Y" } {
            expect "New password: "
            send -- "${mysqlRootPassword}\r"

            expect "Re-enter new password: "
            send -- "${mysqlRootPassword}\r"
        }

        expect "Remove anonymous users? \[Y/n] "
        send -- "${mysqlDeleteAnonymousUsers}\r"

        expect "Disallow root login remotely? \[Y/n] "
        send -- "${mysqlDisallowRootLoginRemotely}\r"

        expect "Remove test database and access to it? \[Y/n] "
        send -- "${mysqlDeleteTestDatabase}\r"

        expect "Reload privilege tables now? \[Y/n] "
        send -- "${mysqlReloadPrivilegeTable}\r"

        expect eof
DONE
}

function main()
{
    appPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    source "${appPath}/../../../libraries/util.bash"
    source "${appPath}/../attributes/default.bash"

    checkRequireSystem
    checkRequireRootUser

    header 'INSTALLING MYSQL'

    checkRequirePort "${mysqlPort}"

    installDependencies
    install
    installCleanUp

    displayOpenPorts
}

main "${@}"