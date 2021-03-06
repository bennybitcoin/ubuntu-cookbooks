#!/bin/bash -e

function install()
{
    "${appPath}/install-server.bash"
    "${appPath}/install-agent.bash" "${@}"
}

function main()
{
    appPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    source "${appPath}/../../../libraries/util.bash"
    source "${appPath}/../attributes/default.bash"

    checkRequireSystem
    checkRequireRootUser

    install "${@}"
    installCleanUp
}

main "${@}"