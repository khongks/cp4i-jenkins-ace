def gitRepo = "https://github.com/khongks/cp4i-jenkins-ace.git"

pipeline {
    agent {
        docker {
            image 'image-registry.openshift-image-registry.svc:5000/jenkins/ace-full:12.0.2.0-ubuntu'
            args '-e GIT_REPO=${gitRepo}'
        }
    }
    stages {
        stage('Git Checkout') {
            steps {
                sh """
                    git clone $GIT_REPO
                    ls -la
                """
            }
        }
    }
}