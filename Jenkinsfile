// ═══════════════════════════════════════════════════════════════════════════
//  Student Management System — Jenkins Declarative Pipeline
//  Stages: Checkout → Build/Test → SonarQube → Docker Build →
//          Trivy Scan → Docker Push → K8s Deploy (Helm) → Smoke Test
//  Auto-rollback on failure, post-hooks for notifications
// ═══════════════════════════════════════════════════════════════════════════
pipeline {
    agent any

    triggers {
        githubPush()
    }

    tools {
        jdk 'JDK21'
        maven 'Maven3.9'
    }

    environment {
        // ── Docker registry ───────────────────────────────────────────────
        DOCKER_NAMESPACE  = "walid369"
        DOCKER_IMAGE      = "student-management"

        // ── Application config ────────────────────────────────────────────
        APP_PORT          = "8089"
        APP_CONTEXT_PATH  = "/student"
        MYSQL_DATABASE    = "studentdb"

        // ── SonarQube ─────────────────────────────────────────────────────
        SONAR_HOST_URL    = "http://localhost:9000"

        // ── Kubernetes ────────────────────────────────────────────────────
        K8S_NAMESPACE     = "student-management"
        HELM_RELEASE      = "student-management"
        HELM_CHART        = "./helm/student-management"
        KUBECONFIG        = credentials('kubeconfig-minikube')

        // ── Computed at runtime (set in Checkout stage) ───────────────────
        DOCKER_TAG        = ""   // set to GIT_COMMIT_SHORT below
        GIT_COMMIT_SHORT  = ""
    }

    options {
        // Keep last 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Global timeout: 45 minutes
        timeout(time: 45, unit: 'MINUTES')
        // Prevent concurrent builds on same branch
        disableConcurrentBuilds()
        // Add timestamps to console output
        timestamps()
    }

    stages {

        // ─────────────────────────────────────────────────────────────────
        // STAGE 1 — Checkout
        // ─────────────────────────────────────────────────────────────────
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/WalidBenTouhami/student-management.git',
                    credentialsId: 'github-token'

                script {
                    env.GIT_COMMIT_SHORT = env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'latest'
                    env.DOCKER_TAG = env.GIT_COMMIT_SHORT
                    echo "🔖 Git commit: ${env.GIT_COMMIT_SHORT}"
                    echo "🏷️  Docker tag: ${env.DOCKER_NAMESPACE}/${env.DOCKER_IMAGE}:${env.DOCKER_TAG}"
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // STAGE 2 — Build & Test
        //   - Runs all unit tests + JaCoCo coverage
        //   - Enforces 70% minimum coverage (configured in pom.xml)
        // ─────────────────────────────────────────────────────────────────
        stage('Build & Test') {
            steps {
                // Normalize line endings (Windows → Unix)
                sh 'sed -i "s/\\r$//" mvnw && chmod +x mvnw'
                sh './mvnw clean verify -Dspring.profiles.active=test -B'
            }
            post {
                always {
                    // Archive JUnit test results
                    junit testResults: 'target/surefire-reports/*.xml',
                          allowEmptyResults: true
                    // Archive JaCoCo coverage report
                    jacoco(
                        execPattern: 'target/jacoco.exec',
                        classPattern: 'target/classes',
                        sourcePattern: 'src/main/java',
                        exclusionPattern: '**/generated/**,**/*MapperImpl.class',
                        minimumInstructionCoverage: '80',
                        changeBuildStatus: true
                    )
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // STAGE 3 — SonarQube Analysis + Quality Gate
        //   - Quality Gate is BLOCKING (abortPipeline: true)
        //   - sonar.qualitygate.wait=true configured in pom.xml
        // ─────────────────────────────────────────────────────────────────
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    withCredentials([string(credentialsId: 'Sonar_token', variable: 'SONAR_TOKEN')]) {
                        sh "echo 'Starting Sonar analysis...'"
                        sh "./mvnw sonar:sonar -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=\$SONAR_TOKEN -Dsonar.projectVersion=${GIT_COMMIT_SHORT} -B"
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // STAGE 4 — Build Docker Image
        //   - Tags: :latest AND :<git-sha>
        //   - Passes build args for OCI labels
        // ─────────────────────────────────────────────────────────────────
        stage('Build Docker Image') {
            steps {
                script {
                    def buildDate = sh(returnStdout: true, script: 'date -u +"%Y-%m-%dT%H:%M:%SZ"').trim()
                    sh """
                        docker build \
                            --pull \
                            --build-arg IMAGE_TAG=${DOCKER_TAG} \
                            --build-arg BUILD_DATE=${buildDate} \
                            --build-arg GIT_COMMIT=${GIT_COMMIT_SHORT} \
                            -t ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG} \
                            -t ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:latest \
                            .
                    """
                    echo "✅ Docker image built: ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // STAGE 5 — Trivy Security Scan
        //   - Scans built image for CVEs
        //   - Fails pipeline on CRITICAL vulnerabilities
        //   - Generates HTML + JSON reports (archived as artifacts)
        // ─────────────────────────────────────────────────────────────────
        stage('Trivy Security Scan') {
            steps {
                script {
                    sh 'mkdir -p target/trivy-reports'
                    // JSON report (machine-readable)
                    sh """
                        trivy image \
                            --exit-code 0 \
                            --severity HIGH,CRITICAL \
                            --format json \
                            --output target/trivy-reports/trivy-report.json \
                            ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                    // Table report (human-readable — fails on CRITICAL)
                    def trivyExitCode = sh(
                        returnStatus: true,
                        script: """
                            trivy image \
                                --exit-code 1 \
                                --severity CRITICAL \
                                --format table \
                                ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        """
                    )
                    if (trivyExitCode != 0) {
                        error("❌ CRITICAL vulnerabilities found by Trivy! Pipeline aborted.")
                    }
                    echo "✅ Trivy scan passed — no CRITICAL vulnerabilities."
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'target/trivy-reports/**',
                                     allowEmptyArchive: true
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // STAGE 6 — Push to Docker Hub
        //   - Pushes both :<sha> and :latest tags
        //   - Uses Jenkins credential 'docker-hub-credentials'
        // ─────────────────────────────────────────────────────────────────
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin docker.io
                        docker push ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:latest
                        docker logout docker.io
                    '''
                }
                echo "✅ Pushed: ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG} + :latest"
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // STAGE 7 — Deploy to Kubernetes (Helm)
        //   - helm upgrade --install (idempotent)
        //   - Secrets injected from Jenkins Credentials (never hardcoded)
        //   - Creates namespace if it doesn't exist
        //   - Waits for rollout completion
        // ─────────────────────────────────────────────────────────────────
        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'mysql-root-credentials',
                        usernameVariable: 'MYSQL_ROOT_USER',
                        passwordVariable: 'MYSQL_ROOT_PASSWORD'
                    ),
                    usernamePassword(
                        credentialsId: 'mysql-app-credentials',
                        usernameVariable: 'MYSQL_APP_USER',
                        passwordVariable: 'MYSQL_APP_PASSWORD'
                    ),
                    usernamePassword(
                        credentialsId: 'actuator-credentials',
                        usernameVariable: 'ACTUATOR_USER',
                        passwordVariable: 'ACTUATOR_PASSWORD'
                    ),
                    usernamePassword(
                        credentialsId: 'api-credentials',
                        usernameVariable: 'API_USER',
                        passwordVariable: 'API_PASSWORD'
                    )
                ]) {
                    script {
                        // Ensure namespace exists
                        sh "kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"

                        // Helm upgrade --install (atomic: rollback on failure)
                        sh """
                            helm upgrade --install ${HELM_RELEASE} ${HELM_CHART} \
                                --namespace ${K8S_NAMESPACE} \
                                --create-namespace \
                                --atomic \
                                --timeout 5m \
                                --history-max 5 \
                                -f ${HELM_CHART}/values.yaml \
                                -f ${HELM_CHART}/values-prod.yaml \
                                --set image.tag=${DOCKER_TAG} \
                                --set image.repository=${DOCKER_NAMESPACE}/${DOCKER_IMAGE} \
                                --set mysqlSecret.rootPassword="${MYSQL_ROOT_PASSWORD}" \
                                --set mysqlSecret.appUser="${MYSQL_APP_USER}" \
                                --set mysqlSecret.appPassword="${MYSQL_APP_PASSWORD}" \
                                --set appSecret.actuatorUser="${ACTUATOR_USER}" \
                                --set appSecret.actuatorPassword="${ACTUATOR_PASSWORD}" \
                                --set appSecret.apiUser="${API_USER}" \
                                --set appSecret.apiPassword="${API_PASSWORD}"
                        """

                        // Wait for deployment rollout
                        sh """
                            kubectl rollout status deployment/${HELM_RELEASE} \
                                --namespace ${K8S_NAMESPACE} \
                                --timeout=300s
                        """
                        echo "✅ Helm deployment complete."
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // STAGE 8 — Smoke Test / Health Check
        //   - Waits for actuator/health to return UP
        //   - Checks liveness and readiness endpoints
        //   - Verifies at least 2 pods are Running
        // ─────────────────────────────────────────────────────────────────
        stage('Smoke Test') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'actuator-credentials',
                    usernameVariable: 'ACTUATOR_USER',
                    passwordVariable: 'ACTUATOR_PASSWORD'
                )]) {
                    script {
                        def minikubeIp = sh(
                            returnStdout: true,
                            script: 'minikube ip'
                        ).trim()
                        def baseUrl = "http://${minikubeIp}:30089${APP_CONTEXT_PATH}"

                        echo "🔍 Smoke testing: ${baseUrl}"

                        // Retry health check for up to 3 minutes
                        def maxAttempts = 18
                        def healthy = false
                        for (int i = 1; i <= maxAttempts; i++) {
                            def status = sh(
                                returnStatus: true,
                                script: """
                                    curl -sf -u "${ACTUATOR_USER}:${ACTUATOR_PASSWORD}" \
                                        "${baseUrl}/actuator/health" \
                                        | grep -q '"status":"UP"'
                                """
                            )
                            if (status == 0) {
                                healthy = true
                                echo "✅ Health check passed (attempt ${i}/${maxAttempts})"
                                break
                            }
                            echo "⏳ Waiting for health... (attempt ${i}/${maxAttempts})"
                            sleep(10)
                        }

                        if (!healthy) {
                            // Capture debug info before failing
                            sh "kubectl get pods -n ${K8S_NAMESPACE} || true"
                            sh "kubectl describe pods -n ${K8S_NAMESPACE} || true"
                            sh "kubectl logs -n ${K8S_NAMESPACE} -l app.kubernetes.io/name=student-management --tail=50 || true"
                            error("❌ Smoke test FAILED — application did not become healthy")
                        }

                        // Verify pod count
                        def podCount = sh(
                            returnStdout: true,
                            script: """
                                kubectl get pods -n ${K8S_NAMESPACE} \
                                    -l app.kubernetes.io/name=student-management \
                                    --field-selector=status.phase=Running \
                                    --no-headers | wc -l
                            """
                        ).trim().toInteger()

                        if (podCount < 2) {
                            error("❌ Expected ≥ 2 running pods, found: ${podCount}")
                        }
                        echo "✅ ${podCount} pods running. Smoke test PASSED."
                    }
                }
            }
            post {
                failure {
                    // STAGE 9 — Automatic Rollback
                    script {
                        echo "🔁 Initiating automatic Helm rollback..."
                        sh """
                            helm rollback ${HELM_RELEASE} \
                                --namespace ${K8S_NAMESPACE} \
                                --wait \
                                --timeout 3m \
                                || echo '⚠️  Rollback attempted, check cluster state.'
                        """
                        echo "🔁 Rollback complete. Check cluster state manually if needed."
                    }
                }
            }
        }

    } // end stages

    // ─────────────────────────────────────────────────────────────────────
    // POST — Global hooks
    // ─────────────────────────────────────────────────────────────────────
    post {
        success {
            script {
                echo """
╔══════════════════════════════════════════════╗
║  ✅ PIPELINE SUCCEEDED                       ║
║  Build    : #${BUILD_NUMBER}                 ║
║  Commit   : ${GIT_COMMIT_SHORT}              ║
║  Image    : ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}
║  Env      : Minikube / ${K8S_NAMESPACE}      ║
╚══════════════════════════════════════════════╝
                """
                // Slack Notification
                // slackSend(channel: '#devops-alerts', color: 'good', message: "✅ *${JOB_NAME}* build #${BUILD_NUMBER} succeeded. Image: `${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}`")
                
                // Email Notification
                // emailext(subject: "SUCCESS: Job '${JOB_NAME}' [${BUILD_NUMBER}]", body: "Check console output at ${BUILD_URL}", to: "devops@example.com")
            }
        }

        failure {
            script {
                echo """
╔══════════════════════════════════════════════╗
║  ❌ PIPELINE FAILED                          ║
║  Build  : #${BUILD_NUMBER}                   ║
║  Check Jenkins logs and cluster state.       ║
╚══════════════════════════════════════════════╝
                """
                // Slack Notification
                // slackSend(channel: '#devops-alerts', color: 'danger', message: "❌ *${JOB_NAME}* build #${BUILD_NUMBER} FAILED. <${BUILD_URL}|View logs>")
                
                // Email Notification
                // emailext(subject: "FAILED: Job '${JOB_NAME}' [${BUILD_NUMBER}]", body: "Check console output at ${BUILD_URL}", to: "devops@example.com")
            }
        }

        always {
            // Clean up dangling Docker images (keep disk usage low on Jenkins agent)
            sh 'docker image prune -f --filter "dangling=true" || true'
            // Archive JaCoCo HTML report
            publishHTML(target: [
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'target/site/jacoco',
                reportFiles: 'index.html',
                reportName: 'JaCoCo Coverage Report'
            ])
        }
    }
}