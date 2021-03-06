#!/bin/bash -e

function main()
{
    local appPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    source "${appPath}/../../attributes/slave.bash"

    local command="cd /tmp &&
                   sudo rm -f -r ubuntu-cookbooks &&
                   sudo git clone https://github.com/gdbtek/ubuntu-cookbooks.git &&
                   sudo /tmp/ubuntu-cookbooks/cookbooks/node-js/recipes/install.bash '${ccmuiJenkinsNodeJSInstallFolder}' '${ccmuiJenkinsNodeJSVersion}'
                   sudo rm -f -r /tmp/ubuntu-cookbooks"

    "${appPath}/../../../../../../tools/run-remote-command.bash" \
        --attribute-file "${appPath}/../attributes/jenkins.bash" \
        --command "${command}" \
        --machine-type 'master-slave'
}

main "${@}"