pipeline {
    agent {
        label 'ops-alpine'
    }
    options {
        disableConcurrentBuilds()
        timestamps()
        ansiColor('xterm')
    }
    stages {
        stage('terraform plan') {
            when {
                not { branch 'master' }
                expression {
                    // Skip if no Terraform files modified
                    filesNotModified = sh(returnStatus: true, script: "git diff-tree --diff-filter=d --no-commit-id --name-only -r ${GIT_COMMIT} | grep -e '\\.tf\$'")
                    if (filesNotModified) { println "INFO: No Terraform files modified. Skipping stage." }
                    return !filesNotModified
                }
            }
            steps {
                container('ops-alpine') {
                    script {
                        def result = sh (returnStdout:true, script:"""
                            ROOT_DIR=\$PWD

                            # Run terraform plan for all modified projects
                            for dir in \$(git diff-tree --diff-filter=d --no-commit-id --name-only -r ${GIT_COMMIT} | sed -ne '/\\.tf\$/p' | sed -e 's|\\(.*\\)/[^/]*|\\1|' | uniq); do
                                cd \$dir

                                # Initialize environment
                                if echo "\$dir" | grep -q "development/"; then
                                    export AWS_PROFILE=develop;
                                    export PLAN_BUCKET=terraform-plans-abaland;
                                else
                                    export AWS_PROFILE=production;
                                    export PLAN_BUCKET=terraform-plans-abaenglish;
                                fi

                                echo "\n[1mInitializing Terraform for \$dir ...[0m[0m"
                                terraform init -input=false
                                echo "\n[1mRunning tflint on \$dir ...[0m[0m"
                                echo "[31m"
                                tflint --force --config=/root/.tflint/tflint.hcl
                                echo "[0m[0m"
                                echo "\n[1mGenerating plan for \$dir ...[0m[0m"
                                planout=\$(echo \$dir | sed -e 's|/|-|')
                                terraform plan -input=false -out=\$planout
                                echo "\n[1mUploading plan for \$dir to S3...[0m[0m"
                                tarball=\${planout}.tar.gz
                                tar zcf /tmp/\$tarball .
                                aws s3 cp /tmp/\$tarball s3://\$PLAN_BUCKET/\$tarball --no-progress

                                cd \$ROOT_DIR
                            done
                        """)

                        def colored = sh (returnStdout:true, script:"echo \"$result\" | term2md")
                        def comment = pullRequest.comment(colored)

                        if (result.contains("issue(s) found:")) {
                            currentBuild.result = "FAILURE";
                        }
                    }
                }
            }
        }
        stage('terraform apply') {
            when {
                branch 'master'
                expression {
                    // Skip if no Terraform files modified
                    filesNotModified = sh(returnStatus: true, script: "git diff-tree --diff-filter=d --no-commit-id --name-only -r -m ${GIT_COMMIT} | grep -e '\\.tf\$'")
                    if (filesNotModified) { println "INFO: No Terraform files modified. Skipping stage." }
                    return !filesNotModified
                }
            }
            steps {
                container('ops-alpine') {
                    script {
                        def result = sh (returnStdout:true, script:"""
                            ROOT_DIR=\$PWD

                            # Run terraform apply for all modified projects
                            for dir in \$(git diff-tree --diff-filter=d --no-commit-id --name-only -r -m ${GIT_COMMIT} | sed -ne '/\\.tf\$/p' | sed -e 's|\\(.*\\)/[^/]*|\\1|' | uniq); do
                                cd \$dir

                                # Initialize environment
                                if echo "\$dir" | grep -q "development/"; then
                                    export AWS_PROFILE=develop;
                                    export PLAN_BUCKET=terraform-plans-abaland;
                                else
                                    export AWS_PROFILE=production;
                                    export PLAN_BUCKET=terraform-plans-abaenglish;
                                fi

                                # Apply plan if available on S3
                                plan=\$(echo \$dir | sed -e 's|/|-|')
                                tarball=\${plan}.tar.gz
                                if aws s3api head-object --bucket \$PLAN_BUCKET --key \$tarball > /dev/null; then
                                    echo "\n[1mDownloading plan for \$dir from S3...[0m[0m";
                                    aws s3 cp s3://\$PLAN_BUCKET/\$tarball . --no-progress;
                                    tar zxf \$tarball;
                                    echo "\n[1mApplying plan for \$dir ...[0m[0m";
                                    terraform apply -input=false \$plan;
                                else
                                    echo "\n[1mError: plan for \$dir not available![0m[0m"
                                fi

                                cd \$ROOT_DIR
                            done
                        """)

                        def colored = sh (returnStdout:true, script:"echo \"$result\" | term2md")
                        def comment = pullRequest.comment(colored)

                        if (result.contains("Error: ")) {
                            currentBuild.result = "FAILURE";
                        }
                    }

                }
            }
        }
    }
}
