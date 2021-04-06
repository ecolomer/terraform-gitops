pipeline {
    agent {
        label 'ops-alpine'
    }
    options {
        disableConcurrentBuilds()
        timestamps()
    }
    stages {
        stage('terraform init') {
            when {
                not { branch 'master' }
            }
            environment {
                AWS_PROFILE="develop"
            }
            steps {
                container('ops-alpine') {
                    sh """
                    ROOT_DIR=\$PWD
                    for dir in \$(git diff-tree --diff-filter=d --no-commit-id --name-only -r ${GIT_COMMIT} | sed -ne '/\\.tf\$/p' | sed -e 's|\\(.*\\)/[^/]*|\\1|' | uniq); do
                        cd \$dir
                        terraform init
                        cd \$ROOT_DIR
                    done
                    """
                }
            }
        }
        stage('terraform apply') {
            when {
                branch 'master'
            }
            steps {
                container('ops-alpine') {
                    sh """
                    terraform version
                    """
                }
            }
        }
    }
}
