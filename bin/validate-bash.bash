#!/bin/bash -e

function main()
{
    local projectPath="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    source "${projectPath}/libraries/util.bash"

    local command='shellcheck'

    checkExistCommand "${command}" "command '${command}' not found. Run '${projectPath}/cookbooks/shell-check/recipes/install.bash' to install"

    find "${projectPath}" -type f -name "*.bash" -exec "${command}" -s bash {} \;
}

main "${@}"