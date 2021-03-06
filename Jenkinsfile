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
                    def retVal = sh(returnStatus: true, script: "git diff-tree --no-commit-id --name-only -r ${GIT_COMMIT} | grep -e '\\.tf\$'")
                    if (retVal) { println "Info: No Terraform files modified. Skipping stage." }
                    return !retVal
                }
            }
            steps {
                container('ops-alpine') {
                    script {
                        def result = sh (returnStdout:true, script:"""
                            ROOT_DIR=\$PWD

                            # Process all modified Terraform configurations
                            for dir in \$(git diff-tree --no-commit-id --name-only -r ${GIT_COMMIT} | sed -ne '/\\.tf\$/p' | sed -e 's|\\(.*\\)/[^/]*|\\1|' | uniq); do
                                cd \$dir

                                if echo "\$dir" | grep -q "development/"; then
                                    export AWS_PROFILE=develop;
                                    export PLAN_BUCKET=terraform-plans-abaland;
                                else
                                    export AWS_PROFILE=production;
                                    export PLAN_BUCKET=terraform-plans-abaenglish;
                                fi

                                # Remove AWS provider from terraform.lock.hcl
                                # Container images have a pre-installed AWS provider
                                [ -f .terraform.lock.hcl ] && sed -i "/aws/,/}/d" .terraform.lock.hcl

                                (set +x; echo "\n[1mProcessing \$dir ...[0m")
                                if ! terraform init -input=false 2>&1; then
                                    (set +x; echo "[31mError: cannot initialize! Review error messages.[0m")
                                    break
                                fi

                                (set +x; echo "\n[1mRunning tflint on \$dir ...[0m")
                                if ! tflint --config=/root/.tflint/tflint.hcl; then
                                    (set +x; echo "[31mError: issues found in current configuration. Review error messages.[0m")
                                    break
                                fi

                                (set +x; echo "\n[1mRunning tfsec on \$dir ...[0m")
                                if ! tfsec --concise-output --no-color; then
                                    (set +x; echo "[31mError: issues found in current configuration. Review error messages.[0m")
                                    break
                                fi

                                (set +x; echo "\n[1mGenerating plan for \$dir ...[0m")
                                conf=\$(echo \$dir | sed -e 's|/|-|')
                                if ! terraform plan -input=false -out=\${conf}.tfplan 2>&1; then
                                    (set +x; echo "[31mError: cannot plan configuration! Review error messages.[0m")
                                    break
                                fi

                                (set +x; echo "\n[1mUploading plan for \$dir to S3...[0m")
                                tar zcf /tmp/\${conf}.tar.gz .
                                if ! aws s3 cp /tmp/\${conf}.tar.gz s3://\$PLAN_BUCKET/\${conf}.tar.gz --no-progress; then
                                    (set +x; echo "[31mError: cannot upload to S3! Review error messages.[0m")
                                    break
                                fi

                                cd \$ROOT_DIR
                            done
                        """)

                        // Display script output
                        println "\n\u001B[1mTerraform plan stage output\u001B[0m\n"

                        // Prepare pull request text
                        def colored = sh (returnStdout:true, script:"echo \"$result\" | sed -e '/unchanged [A-Za-z]\\+ hidden/s/#//' | term2md")

                        // Add results to pull request comment
                        if (env.CHANGE_ID) { pullRequest.comment(colored) }

                        // If issues were found, fail build
                        if (result.contains("Error:")) { currentBuild.result = "FAILURE"; }
                    }
                }
            }
        }
        stage('terraform apply') {
            when {
                branch 'master'
                expression {
                    // Skip if no Terraform files modified
                    def retVal = sh(returnStatus: true, script: "git diff-tree --no-commit-id --name-only -r -m ${GIT_COMMIT} | grep -e '\\.tf\$'")
                    if (retVal) { println "Info: No Terraform files modified. Skipping stage." }
                    return !retVal
                }
            }
            steps {
                container('ops-alpine') {
                    script {
                        def result = sh (returnStdout:true, script:"""
                            ROOT_DIR=\$PWD

                            # Process all modified Terraform configurations
                            for dir in \$(git diff-tree --no-commit-id --name-only -r -m ${GIT_COMMIT} | sed -ne '/\\.tf\$/p' | sed -e 's|\\(.*\\)/[^/]*|\\1|' | uniq); do
                                cd \$dir

                                if echo "\$dir" | grep -q "development/"; then
                                    export AWS_PROFILE=develop;
                                    export PLAN_BUCKET=terraform-plans-abaland;
                                else
                                    export AWS_PROFILE=production;
                                    export PLAN_BUCKET=terraform-plans-abaenglish;
                                fi

                                # Apply plan if available on S3
                                conf=\$(echo \$dir | sed -e 's|/|-|')
                                if aws s3api head-object --bucket \$PLAN_BUCKET --key \${conf}.tar.gz > /dev/null; then

                                    (set +x; echo "\n[1mDownloading plan for \$dir from S3...[0m")
                                    if ! aws s3 cp s3://\$PLAN_BUCKET/\${conf}.tar.gz . --no-progress; then
                                        (set +x; echo "[31mError: cannot download from S3! Review error messages.[0m")
                                        break
                                    fi

                                    tar zxf \${conf}.tar.gz
                                    (set +x; echo "\n[1mApplying plan for \$dir ...[0m")
                                    if ! terraform apply -input=false \${conf}.tfplan; then
                                        (set +x; echo "[31mError: cannot apply configuration! Review error messages.[0m")
                                        break
                                    fi
                                else
                                    (set +x; echo "\n[31mError: plan for \$dir not available![0m")
                                    break
                                fi

                                (set +x; echo "\n[1mRemoving plan for \$dir from S3...[0m";)
                                if ! aws s3 rm s3://\$PLAN_BUCKET/\${conf}.tar.gz --quiet; then
                                    (set +x; echo "[31mError: cannot remove from S3! Review error messages.[0m")
                                    break
                                fi

                                cd \$ROOT_DIR
                            done
                        """)

                        // Display script output
                        println "\n\u001B[1mTerraform apply stage output\u001B[0m\n$result"

                        // If issues were found, fail build
                        if (result.contains("Error:")) { currentBuild.result = "FAILURE"; }
                    }
                }
            }
        }
    }
}
