// Image variables
def buildBarImage = "image-registry.openshift-image-registry.svc:5000/jenkins/ace-buildbar:12.0.2.0-ubuntu"
// def ocImage = "quay.io/openshift/origin-cli"
def ocImage = "image-registry.openshift-image-registry.svc:5000/jenkins/oc-deploy:latest"
// K8S secret Names
// def secretName = "jenkins-ssh-ns-gitibm"
// Params for Git Checkout-Stage
def gitRepo = "https://github.com/khongks/cp4i-jenkins-ace.git"
def gitDomain = "github.com"
// Params for Build Bar Stage
def barName = "ExampleRestApi"
def appName = "ExampleRestApi"
def projectDir = "cp4i-jenkins-ace"
// Params for Deploy Bar Stage
def serverName = "foobar"
def namespace = "ace"
def configuration_list = ""
def host = "ace-dashboard-dash.ace.svc.cluster.local"
def port = "3443"
// oc get secret -n ace ace-dashboard-dash -ojson | jq -r .data.ibmAceControlApiKey | base64 -d
def ibmAceSecretName = "ace-dashboard-dash"
def imageName = "icr.io/appc-dev/ace-server@sha256:c58fc5a0975314e6a8e72f2780163af38465e6123e3902c118d8e24e798b7b01"
def imagePullSecret = "ibm-entitlement-key"
// curl -X GET -k -H "x-ibm-ace-control-apikey: bb0f7e21-8e8a-40da-9b9f-66371c6c4142" https://ace-dashboard-dash.ace.svc.cluster.local:3443/v1/directories/file | jq -r token
// curl -X GET -k -H "x-ibm-ace-control-apikey: $API_KEY" https://$HOST:$PORT/v1/directories/$BAR_FILE   

podTemplate(
    serviceAccount: "jenkins-jenkins-dev",
    // volumes: [ secretVolume(secretName: "${secretName}", mountPath: '/etc/ssh-key') ],
    containers: [
        containerTemplate(name: 'buildbar', image: "${buildBarImage}", workingDir: "/home/jenkins", ttyEnabled: true, envVars: [
            envVar(key: 'BAR_NAME', value: "${barName}"),
            envVar(key: 'APP_NAME', value: "${appName}"),
            envVar(key: 'PROJECT_DIR', value: "${projectDir}"),
        ]),
        containerTemplate(name: 'oc-deploy', image: "${ocImage}", workingDir: "/home/jenkins", ttyEnabled: true, envVars: [
            envVar(key: 'NAMESPACE', value: "${namespace}"),
            envVar(key: 'BAR_NAME', value: "${barName}"),
            envVar(key: 'APP_NAME', value: "${appName}"),
            envVar(key: 'CONFIGURATION_LIST', value: "${configuration_list}"),
            envVar(key: 'HOST', value: "${host}"),
            envVar(key: 'PORT', value: "${port}"),
            // envVar(key: 'API_KEY', value: "bb0f7e21-8e8a-40da-9b9f-66371c6c4142"),
            envVar(key: 'API_KEY_NAME', value: "${ibmAceSecretName}"),
            envVar(key: 'PROJECT_DIR', value: "${projectDir}"),
        ]),
        // containerTemplate(name: 'oc-build', image: "k3integrations/kubectl", workingDir: "/home/jenkins", ttyEnabled: true, envVars: [
        //     envVar(key: 'SERVER_NAME', value: "${serverName}"),
        //     envVar(key: 'NAMESPACE', value: "${namespace}"),
        //     envVar(key: 'BAR_FILE', value: "${barName}"),
        //     envVar(key: 'CONFIGURATION_LIST', value: "${configuration_list}"),
        //     envVar(key: 'IMAGE_NAME', value: "${imageName}"),
        //     envVar(key: 'IMAGE_PULLSECRET', value: "${imagePullSecret}"),
        //     envVar(key: 'HOST', value: "${host}"),
        //     envVar(key: 'PORT', value: "${port}"),
        //     envVar(key: 'PROJECT_DIR', value: "${projectDir}"),
        //     //secretEnvVar(key: 'API_KEY', secretKey: "ibmAceControlApiKey", secretName: "${ibmAceSecretName}"),
        //     envVar(key: 'API_KEY_NAME', value: "${ibmAceSecretName}"),
        // ]),
        containerTemplate(name: 'jnlp', image: "jenkins/jnlp-slave:latest", ttyEnabled: true, workingDir: "/home/jenkins", envVars: [
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
                        git clone $GIT_REPO
                        ls -la
                    """
                }
            }
        }
        stage('Build Bar File') {
            container("buildbar") {
                stage('build bar') {
                    sh label: '', script: '''#!/bin/bash
                        Xvfb -ac :99 &
                        export DISPLAY=:99
                        export LICENSE=accept
                        pwd
                        source /opt/ibm/ace-12/server/bin/mqsiprofile
                        cd $PROJECT_DIR
                        mqsicreatebar -data . -b $BAR_NAME.bar -a $APP_NAME -cleanBuild -trace -configuration . 
                        ls -lha
                        '''
                }
            }
        }
        stage('Upload Bar File') {
            container("oc-deploy") {
                stage('upload bar') {
                    sh label: '', script: '''#!/bin/bash
                        set -e
                        cd $PROJECT_DIR
                        ls -lha
                        API_KEY=`oc get secret $API_KEY_NAME -n $NAMESPACE -ojson | jq -r .data.ibmAceControlApiKey | base64 -d`
                        echo "API_KEY: $API_KEY"
                        curl -X PUT -k -H "x-ibm-ace-control-apikey: $API_KEY" https://$HOST:$PORT/v1/directories/$BAR_FILE > /dev/null
                        
                        // export PAYLOAD=`curl -X GET -k -H "x-ibm-ace-control-apikey: $API_KEY" https://$HOST:$PORT/v1/directories/$BAR_FILE`
                        // export TOKEN=`echo $PAYLOAD | jq -r .token`}
                        // curl -k -H "x-ibm-ace-control-apikey: $API_KEY" -T $BAR_FILE.bar https://$HOST:$PORT/v1/directories/$BAR_FILE/bars/$BAR_FILE.bar
                        // wget https://raw.github.ibm.com/cpat/cp4i-generic-asset-us0-gitops/ace-v11.0.0.9/ace/basic/ace-server.yaml?token=AACAQSFUBDBDABJQTLVMP327MUOIG -O yaml.temp
                        // source /dev/stdin <<<"$(echo 'cat <<EOF >final.temp'; cat yaml.temp; echo EOF;)"
                        // cat final.temp
                        // oc config view
                        '''
                }
            }
        }
        // https://ace-dashboard-dash:3443/v1/directories/file?1bd395f5-7cb8-4379-921c-536ea29a7af7 
        stage('Deploy Intergration Server') {
            container("oc-deploy") {
                stage('deploy server') {
                    sh label: '', script: '''#!/bin/bash
                        set -e
                        cd $PROJECT_DIR
                        API_KEY=`oc get secret $API_KEY_NAME -n $NAMESPACE -ojson | jq -r .data.ibmAceControlApiKey | base64 -d`
                        export TOKEN=`curl -X GET -k -H "x-ibm-ace-control-apikey: $API_KEY" https://$HOST:$PORT/v1/directories/$BAR_FILE | jq -r .token`
                        sed -e "s/{{NAME}}/$APP_NAME/g" \
                            -e "s/{{HOST}}/$HOST/g" \
                            -e "s/{{PORT}}/$PORT/g" \
                            -e "s/{{TOKEN}}/$TOKEN/g" \
                            integration-server.yaml.tmpl > integration-server.yaml
                        oc apply -f integration-server.yaml
                        
                        // curl -k -H "x-ibm-ace-control-apikey: $API_KEY" -T $BAR_FILE.bar https://$HOST:$PORT/v1/directories/$BAR_FILE/bars/$BAR_FILE.bar
                        // wget https://raw.github.ibm.com/cpat/cp4i-generic-asset-us0-gitops/ace-v11.0.0.9/ace/basic/ace-server.yaml?token=AACAQSFUBDBDABJQTLVMP327MUOIG -O yaml.temp
                        // source /dev/stdin <<<"$(echo 'cat <<EOF >final.temp'; cat yaml.temp; echo EOF;)"

                        // oc config view
                        // oc apply -f final.temp
                        '''
                }
            }
        }
    }
}