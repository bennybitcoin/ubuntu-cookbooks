#!/bin/bash -e

function main()
{
    # Load Libraries

    local appPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    source "${appPath}/../../../../../cookbooks/jenkins/attributes/master.bash"
    source "${appPath}/../../../../../cookbooks/mount-hd/attributes/default.bash"
    source "${appPath}/../../../../../cookbooks/nginx/attributes/default.bash"
    source "${appPath}/../../../../../libraries/util.bash"
    source "${appPath}/../../../libraries/util.bash"
    source "${appPath}/../attributes/master.bash"

    # Extend HD

    extendOPTPartition "${ccmuiJenkinsDisk}" "${ccmuiJenkinsMountOn}" "${mounthdPartitionNumber}"

    # Install Apps

    local hostName='jenkins.ccmui.adobe.com'

    "${appPath}/../../../../essential.bash" "${hostName}"
    "${appPath}/../../../../../cookbooks/maven/recipes/install.bash"
    "${appPath}/../../../../../cookbooks/node-js/recipes/install.bash" "${ccmuiJenkinsNodeJSInstallFolder}" "${ccmuiJenkinsNodeJSVersion}"
    "${appPath}/../../../../../cookbooks/jenkins/recipes/install-master.bash"
    "${appPath}/../../../../../cookbooks/jenkins/recipes/install-master-plugins.bash" "${ccmuiJenkinsInstallPlugins[@]}"
    "${appPath}/../../../../../cookbooks/jenkins/recipes/safe-restart-master.bash"
    "${appPath}/../../../../../cookbooks/ps1/recipes/install.bash" --host-name "${hostName}" --users "${jenkinsUserName}"

    # Config SSH and GIT

    addUserAuthorizedKey "$(whoami)" "$(whoami)" "$(cat "${appPath}/../files/default/authorized_keys")"
    addUserSSHKnownHost "${jenkinsUserName}" "${jenkinsGroupName}" "$(cat "${appPath}/../files/default/known_hosts")"

    configUserGIT "${jenkinsUserName}" "${ccmuiJenkinsGITUserName}" "${ccmuiJenkinsGITUserEmail}"
    generateUserSSHKey "${jenkinsUserName}"

    # Config Nginx

    "${appPath}/../../../../../cookbooks/nginx/recipes/install.bash"

    header 'CONFIGURING NGINX PROXY'

    local nginxConfigData=(
        '__NGINX_PORT__' "${nginxPort}"
        '__JENKINS_TOMCAT_HTTP_PORT__' "${jenkinsTomcatHTTPPort}"
    )

    createFileFromTemplate "${appPath}/../templates/default/nginx.conf.conf" "${nginxInstallFolder}/conf/nginx.conf" "${nginxConfigData[@]}"

    stop "${nginxServiceName}"
    start "${nginxServiceName}"

    # Clean Up

    cleanUpSystemFolders
    cleanUpITMess

    # Display Notice

    displayNotice "${jenkinsUserName}"
}

main "${@}"