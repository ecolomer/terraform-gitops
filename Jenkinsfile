pipeline {
    agent {
        docker {
            image 'builder-ops:alpine'
            args '-v /Users/Eleatzar/.ssh:/root/.ssh'
        }
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
                sh """
                for dir in \$(git diff-tree --diff-filter=d --no-commit-id --name-only -r ${GIT_COMMIT} | sed -ne '/\\.tf\$/p' | sed -e 's|\\(.*\\)/[^/]*|\\1|' | uniq); do
                    pushd dir
                    terraform init
                    popd
                done
                """
            }
        }
        stage('terraform apply') {
            when {
                branch 'master'
            }
            steps {
                sh """
                terraform version
                """
            }
        }
    }
}
