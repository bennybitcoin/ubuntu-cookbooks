#!/bin/bash -e

function main()
{
    local appPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    "${appPath}/essential.bash"

    "${appPath}/../cookbooks/tomcat/recipes/install.bash"
    "${appPath}/../cookbooks/nginx/recipes/install.bash"
}

main "${@}"