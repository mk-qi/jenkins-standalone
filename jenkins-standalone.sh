#!/bin/bash
set -e
# production
HOST="$(ip a |grep 'global bond0.11' |cut -d/ -f1|awk  '{print $2}')"
# test
[[ "x$HOST" == "x" ]] && {
	HOST="$(ip a |grep 'global enp0s8' |cut -d/ -f1|awk  '{print $2}')"
}
PORT="9000" 
# $JENKINS_VERSION should be an LTS release
JENKINS_VERSION="1.596.1"

# List of Jenkins plugins, in the format "${PLUGIN_NAME}/${PLUGIN_VERSION}"
JENKINS_PLUGINS=(
    "credentials/1.22"
    "email-ext/2.39"
    "git/2.3.5"
    "git-client/1.16.1"
    "greenballs/1.14"
    "hipchat/0.1.8"
    "job-dsl/1.29"
    "logstash/1.0.3"
    "metadata/1.1.0b"
    "mesos/0.6.0"
    "monitoring/1.55.0"
    "parameterized-trigger/2.25"
    "saferestart/0.3"
    "scm-api/0.2"
    "script-security/1.13"
    "ssh-credentials/1.10"
    "token-macro/1.10"
)

JENKINS_WAR_MIRROR="http://mirrors.jenkins-ci.org/war-stable"
JENKINS_PLUGINS_MIRROR="http://mirrors.jenkins-ci.org/plugins"

# Ensure we have an accessible wget
command -v wget > /dev/null
if [[ $? != 0 ]]; then
    echo "Error: wget not found in \$PATH"
    echo
    exit 1
fi

# Accept ZooKeeper paths on the command line
if [[ ! $# > 3 ]]; then
    echo "Usage: $0 -z zk://10.132.188.212:2181[, ... ]/mesos"
    echo
    exit 1
fi

while [[ $# > 1 ]]; do
    key="$1"
    shift
    case $key in
        -z|--zookeeper)
            ZOOKEEPER_PATHS="$1"
            shift
            ;;
        *)
            echo "Unknown option: ${key}"
            exit 1
            ;;
    esac
done

# Jenkins WAR file
if [[ ! -f "jenkins.war" ]]; then
    wget -nc "${JENKINS_WAR_MIRROR}/${JENKINS_VERSION}/jenkins.war"
fi

# Jenkins plugins
[[ ! -d "plugins" ]] && mkdir "plugins"
for plugin in ${JENKINS_PLUGINS[@]}; do
    IFS='/' read -a plugin_info <<< "${plugin}"
    plugin_path="${plugin_info[0]}/${plugin_info[1]}/${plugin_info[0]}.hpi"
    wget -nc -P plugins "${JENKINS_PLUGINS_MIRROR}/${plugin_path}"
done

# Jenkins config files
sed -i "s!_MAGIC_ZOOKEEPER_PATHS!${ZOOKEEPER_PATHS}!" config.xml
sed -i "s!_MAGIC_JENKINS_URL!http://${HOST}:${PORT}!" jenkins.model.JenkinsLocationConfiguration.xml

# Start the master
export JENKINS_HOME="$(pwd)"
java -jar jenkins.war \
    -Djava.awt.headless=true \
    --webroot=war \
    --httpPort=${PORT} \
    --ajp13Port=-1 \
    --httpListenAddress=0.0.0.0 \
    --ajp13ListenAddress=127.0.0.1 \
    --preferredClassLoader=java.net.URLClassLoader \
    --logfile=../jenkins.log
