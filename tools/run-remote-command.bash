#!/bin/bash -e

function displayUsage()
{
    local scriptName="$(basename "${BASH_SOURCE[0]}")"

    echo -e "\033[1;33m"
    echo    "SYNOPSIS :"
    echo    "    ${scriptName}"
    echo    "        --help"
    echo    "        --async             <true | false>"
    echo    "        --attribute-file    <ATTRIBUTE-FILE>"
    echo    "        --command           <COMMAND>"
    echo    "        --machine-type      <MACHINE-TYPE>"
    echo -e "\033[1;35m"
    echo    "DESCRIPTION :"
    echo    "    --help              Help page"
    echo    "    --async             Run command asynchronously. Default is 'false'"
    echo    "    --attribute-file    Path to attribute file (require). Sample file :"
    echo -e "\033[1;32m"
    echo    "                        #!/bin/bash -e"
    echo    "                        user='root'"
    echo    "                        master='master.domain.com'"
    echo    "                        slaves=("
    echo    "                            'slave-1.domain.com'"
    echo    "                            'slave-2.domain.com'"
    echo    "                        )"
    echo    "                        identityFile='/data/my-private.pem'"
    echo -e "\033[1;35m"
    echo    "    --command           Command that will be run in remote servers (require)"
    echo    "    --machine-type      Machine type (require)"
    echo    "                        Valid machine type : 'master', 'slave', or 'master-slave'"
    echo -e "\033[1;36m"
    echo    "EXAMPLES :"
    echo    "    ./${scriptName} --help"
    echo    "    ./${scriptName} --attribute-file '/attribute.file' --command 'date' --machine-type 'slave'"
    echo    "    ./${scriptName} --async 'true' --attribute-file '/attribute.file' --command 'date' --machine-type 'slave'"
    echo -e "\033[0m"

    exit "${1}"
}

function run()
{
    local async="${1}"
    local command="${2}"
    local machineType="${3}"

    # Populate Machine List

    local machines=()

    if [[ "${machineType}" = 'master' || "${machineType}" = 'master-slave' ]]
    then
        machines+=("${master}")
    fi

    if [[ "${machineType}" = 'slave' || "${machineType}" = 'master-slave' ]]
    then
        machines+=("${slaves[@]}")
    fi

    # Built Prompt

    # shellcheck disable=SC2016
    local prompt='echo -e "\033[1;36m<\033[31m$(whoami)\033[34m@\033[33m$(hostname)\033[36m><\033[35m$(pwd)\033[36m>\033[0m"'

    # Get Identity File Option

    if [[ "$(isEmptyString "${identityFile}")" = 'false' && -f "${identityFile}" ]]
    then
        local identityOption=('-i' "${identityFile}")
    else
        local identityOption=()
    fi

    # Machine Walker

    local machine=''

    for machine in "${machines[@]}"
    do
        header "${machine}"

        if [[ "${async}" = 'true' ]]
        then
            # shellcheck disable=SC2029
            ssh "${identityOption[@]}" -n "${user}@${machine}" "${prompt} && ${command}" &
        else
            # shellcheck disable=SC2029
            ssh "${identityOption[@]}" -n "${user}@${machine}" "${prompt} && ${command}"
        fi
    done

    if [[ "${async}" = 'true' ]]
    then
        wait
    fi
}

function main()
{
    appPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local optCount="${#}"

    source "${appPath}/../libraries/util.bash"

    while [[ "${#}" -gt '0' ]]
    do
        case "${1}" in
            --help)
                displayUsage 0
                ;;

            --async)
                shift

                if [[ "${#}" -gt '0' ]]
                then
                    local async="${1}"
                fi

                ;;

            --attribute-file)
                shift

                if [[ "${#}" -gt '0' ]]
                then
                    local attributeFile="${1}"
                fi

                ;;

            --command)
                shift

                if [[ "${#}" -gt '0' ]]
                then
                    local command="$(trimString "${1}")"
                fi

                ;;

            --machine-type)
                shift

                if [[ "${#}" -gt '0' ]]
                then
                    local machineType="$(trimString "${1}")"
                fi

                ;;

            *)
                shift
                ;;
        esac
    done

    # Validate Opt

    if [[ "${optCount}" -lt '1' ]]
    then
        displayUsage 0
    fi

    # Validate Async

    if [[ "$(isEmptyString "${async}")" = 'true' ]]
    then
        local async='false'
    fi

    checkTrueFalseString "${async}"

    # Validate Attribute File

    if [[ ! -f "${attributeFile}" ]]
    then
        error "\nERROR : file '${attributeFile}' not found"
        displayUsage 1
    else
        source "${attributeFile}"
    fi

    # Validate Command

    if [[ "$(isEmptyString "${command}")" = 'true' ]]
    then
        error "\nERROR : command not found"
        displayUsage 1
    fi

    # Validate Machine Type

    if [[ "${machineType}" != 'master' && "${machineType}" != 'slave' && "${machineType}" != 'master-slave' ]]
    then
        error "\nERROR : machineType must be 'master', 'slave', or 'master-slave'"
        displayUsage 1
    fi

    # Run

    run "${async}" "${command}" "${machineType}"
}

main "${@}"