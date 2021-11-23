// Image variables
def buildBarImage = "image-registry.openshift-image-registry.svc:5000/jenkins/ace-docker:latest"
def ocImage = "quay.io/openshift/origin-cli"
// K8S secret Names
def secretName = "jenkins-ssh-ns-gitibm"
// Params for Git Checkout-Stage
def gitRepo = "git@github.ibm.com:cpat/cp4i-jenkins-ace.git"
def gitDomain = "github.ibm.com"
// Params for Build Bar Stage
def barName = "file"
def appName = "file"
def projectDir = "cp4i-jenkins-ace"
// Params for Deploy Bar Stage
def serverName = "foobar"
def namespace = "cp4i"
def configuration_list = ""
def host = "ace-db-production-dash.cp4i.svc.cluster.local"
def port = "3443"
def ibmAceSecretName = "ace-db-production-dash"
def imageName = "cp.icr.io/cp/appc/ace-server-prod"
def imagePullSecret = "ibm-entitlement-key"

podTemplate(
    serviceAccount: "cluster-admin",
    volumes: [ secretVolume(secretName: "${secretName}", mountPath: '/etc/ssh-key') ],
    containers: [
        containerTemplate(name: 'buildbar', image: "${buildBarImage}", workingDir: "/home/jenkins", ttyEnabled: true, envVars: [
            envVar(key: 'BAR_NAME', value: "${barName}"),
            envVar(key: 'APP_NAME', value: "${appName}"),
            envVar(key: 'PROJECT_DIR', value: "${projectDir}"),
        ]),
        containerTemplate(name: 'oc-image', image: "${ocImage}", workingDir: "/home/jenkins", ttyEnabled: true, envVars: [
            envVar(key: 'BAR_NAME', value: "${barName}"),
            envVar(key: 'APP_NAME', value: "${appName}"),
            envVar(key: 'PROJECT_DIR', value: "${projectDir}"),
        ]),
        containerTemplate(name: 'curl-image', image: "k3integrations/kubectl", workingDir: "/home/jenkins", ttyEnabled: true, envVars: [
            envVar(key: 'SERVER_NAME', value: "${serverName}"),
            envVar(key: 'NAMESPACE', value: "${namespace}"),
            envVar(key: 'BAR_FILE', value: "${barName}"),
            envVar(key: 'CONFIGURATION_LIST', value: "${configuration_list}"),
            envVar(key: 'IMAGE_NAME', value: "${imageName}"),
            envVar(key: 'IMAGE_PULLSECRET', value: "${imagePullSecret}"),
            envVar(key: 'HOST', value: "${host}"),
            envVar(key: 'PORT', value: "${port}"),
            envVar(key: 'PROJECT_DIR', value: "${projectDir}"),
            secretEnvVar(key: 'API_KEY', secretKey: "ibmAceControlApiKey", secretName: "${ibmAceSecretName}"),
        ]),
        containerTemplate(name: 'jnlp', image: "jenkins/jnlp-slave:4.0.1-1", ttyEnabled: true, workingDir: "/home/jenkins", envVars: [
            envVar(key: 'HOME', value: '/home/jenkins'),
            envVar(key: 'GIT_REPO', value: "${gitRepo}"),
            envVar(key: 'GIT_DOMAIN', value: "${gitDomain}"),
        ])
  ]) {
    node(POD_LABEL) {
        stage('Git Checkout') {
            container("jnlp") {
                stage('copy ssh key to home directory') {
                    sh """
                        eval \$(ssh-agent -s )
                        mkdir ~/.ssh
                        ssh-add /etc/ssh-key/ssh-privatekey
                        ssh-keyscan -H $GIT_DOMAIN >> ~/.ssh/known_hosts
                        git clone $GIT_REPO
                        ls -la
                    """
                }
            }
        }
        stage('Build Bar File') {
            container("buildbar") {
                stage('get pods from cluster') {
                    sh label: '', script: '''#!/bin/bash
                        Xvfb -ac :100 &
                        export DISPLAY=:100
                        export LICENSE=accept
                        pwd
                        source /opt/ibm/ace-11/server/bin/mqsiprofile
                        cd $PROJECT_DIR
                        mqsicreatebar -data . -b $BAR_NAME.bar -a $APP_NAME -cleanBuild -trace -configuration . 
                        ls -lha
                        '''
                }
            }
        }
        stage('Deploy Bar File') {
            container("curl-image") {
                stage('upload bar file to cluster') {
                    sh label: '', script: '''#!/bin/bash
                        set -e
                        cd $PROJECT_DIR
                        ls -lha
                        curl -X PUT -k -H "x-ibm-ace-control-apikey: $API_KEY" https://$HOST:$PORT/v1/directories/$BAR_FILE > /dev/null
                        export PAYLOAD=`curl -X GET -k -H "x-ibm-ace-control-apikey: $API_KEY" https://$HOST:$PORT/v1/directories/$BAR_FILE`
                        export TOKEN=`echo $PAYLOAD | jq -r .token`
                        curl -k -H "x-ibm-ace-control-apikey: $API_KEY" -T $BAR_FILE.bar https://$HOST:$PORT/v1/directories/$BAR_FILE/bars/$BAR_FILE.bar
                        wget https://raw.github.ibm.com/cpat/cp4i-generic-asset-us0-gitops/ace-v11.0.0.9/ace/basic/ace-server.yaml?token=AACAQSFUBDBDABJQTLVMP327MUOIG -O yaml.temp
                        source /dev/stdin <<<"$(echo 'cat <<EOF >final.temp'; cat yaml.temp; echo EOF;)"
                        cat final.temp
                        kubectl config view
                        '''
                }
            }
        }
        stage('Deploy Intergration Server') {
            container("oc-image") {
                stage('upload bar file to cluster') {
                    sh label: '', script: '''#!/bin/bash
                        set -e
                        cd $PROJECT_DIR
                        oc config view
                        oc apply -f final.temp
                        '''
                }
            }
        }
    }
}