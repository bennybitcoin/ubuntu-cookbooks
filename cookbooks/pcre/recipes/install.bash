#!/bin/bash

function installDependencies()
{
    runAptGetUpdate

    installAptGetPackage 'build-essential'
}

function install()
{
    # Clean Up

    rm -rf "${pcreInstallFolder}"
    mkdir -p "${pcreInstallFolder}"

    # Install

    local currentPath="$(pwd)"
    local tempFolder="$(getTemporaryFolder)"

    unzipRemoteFile "${pcreDownloadURL}" "${tempFolder}"
    cd "${tempFolder}" &&
    "${tempFolder}/configure" \
        --prefix="${pcreInstallFolder}" \
        "${pcreEnableEBCDIC}" \
        "${pcreEnableJIT}" \
        "${pcreEnablePCRE16}" \
        "${pcreEnablePCRE32}" \
        "${pcreEnablePCREGrepLibBZ2}" \
        "${pcreEnablePCREGrepLibZ}" \
        "${pcreEnableUnicodeProperties}" \
        "${pcreEnableUTF8}" \
        "${pcreEnableUTF}" &&
    make &&
    make install
    rm -rf "${tempFolder}"
    cd "${currentPath}"

    # Config Profile

    local profileConfigData=('__INSTALL_FOLDER__' "${pcreInstallFolder}")

    createFileFromTemplate "${appPath}/../files/profile/pcre.sh" '/etc/profile.d/pcre.sh' "${profileConfigData[@]}"

    # Display Version

    info "\n$("${pcreInstallFolder}/bin/pcregrep" -V 2>&1)"
}

function main()
{
    appPath="$(cd "$(dirname "${0}")" && pwd)"

    source "${appPath}/../../../lib/util.bash" || exit 1
    source "${appPath}/../attributes/default.bash" || exit 1

    checkRequireDistributor

    header 'INSTALLING PCRE'

    checkRequireRootUser

    installDependencies
    install
    installCleanUp
}

main "${@}"