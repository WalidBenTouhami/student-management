pipeline {
    agent any

    tools {
        jdk 'JDK25'
        maven 'Maven-3.9.16'
    }

    environment {
        APP_ENV = "DEV"
        DOCKER_REGISTRY = "docker.io"
        DOCKER_IMAGE = "esprit/student-management"
        DOCKER_TAG = "${env.BUILD_ID}"
        K8S_NAMESPACE = "devops-tools"
        SONAR_HOST_URL = "http://192.168.56.10:9000"
        // Email — Gmail SMTP (déduit des headers email reçus le 29/06/2026)
        MAIL_FROM     = "walid.bentouhami@esprit.tn"
        MAIL_SENDER   = "ds.walid.bentouhami@gmail.com"
        MAIL_TO       = "walid.bentouhami@esprit.tn"
        // Credentials Jenkins
        SONAR_TOKEN = credentials('sonar-token')
        GITHUB_CREDENTIALS = credentials('github-credentials')
        MYSQL_PASSWORD = credentials('mysql-password')
        MYSQL_ROOT_PASSWORD = credentials('mysql-root-password')
        GRAFANA_ADMIN_PASSWORD = credentials('grafana-admin-password')
        APP_SECURITY_PASSWORD = credentials('app-api-password')
        // Credential Kubernetes (Fichier Kubeconfig en tant que Secret File)
        KUBECONFIG = credentials('k8s-kubeconfig')
    }

    stages {
        // ============================================================
        // 1. CHECKOUT DU CODE
        // ============================================================
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // ============================================================
        // 2. BUILD MAVEN
        // ============================================================
        stage('Build') {
            steps {
                sh 'chmod +x mvnw && ./mvnw clean compile'
            }
        }

        // ============================================================
        // 3. TESTS UNITAIRE
        // ============================================================
        stage('Test & Coverage') {
            steps {
                sh '''
                    chmod +x mvnw
                    ./mvnw clean test jacoco:report --no-transfer-progress
                '''
            }
            post {
                always {
                    // Publie les résultats de tests
                    junit '**/target/surefire-reports/*.xml'
                    
                    // Publie le rapport JaCoCo pour Jenkins
                    jacoco(
                        execPattern: 'target/*.exec',
                        classPattern: 'target/classes',
                        sourcePattern: 'src/main/java',
                        exclusionPattern: 'src/test/*'
                    )
                }
                success {
                    echo "✅ Tests passed with sufficient coverage"
                }
            }
        }

        // ============================================================
        // 3.5. JACOCO QUALITY GATE
        // ============================================================
        stage('JaCoCo Quality Gate') {
            steps {
                script {
                    def coverage = sh(
                        script: '''
                            awk -F, '{
                                if (NR > 1) {
                                    missed += $4;
                                    covered += $5;
                                }
                            } END {
                                if (missed + covered > 0)
                                    printf "%.2f", (covered / (missed + covered)) * 100
                                else
                                    print "0"
                            }' target/site/jacoco/jacoco.csv
                        ''',
                        returnStdout: true
                    ).trim().toDouble()

                    echo "📊 Couverture JaCoCo : ${coverage}%"

                    if (coverage < 70.0) {
                        error "❌ JaCoCo Quality Gate échoué ! Couverture = ${coverage}% (minimum requis : 70%)"
                    } else {
                        echo "✅ JaCoCo Quality Gate passé avec succès (${coverage}%)"
                    }
                }
            }
        }

        // ============================================================
        // 4. ANALYSE SONARQUBE
        // ============================================================
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "chmod +x mvnw && ./mvnw sonar:sonar -Dsonar.projectKey=student-management-pipeline -Dsonar.projectName='Student Management Pipeline' -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.token=${SONAR_TOKEN} -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml"
                }
            }
        }

        // ============================================================
        // 5. QUALITY GATE
        // ============================================================
        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // ============================================================
        // 6. PACKAGE (JAR)
        // ============================================================
        stage('Package') {
            steps {
                sh 'chmod +x mvnw && ./mvnw package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }

        // ============================================================
        // 7. BUILD DOCKER IMAGE (DIRECTLY IN MINIKUBE)
        // ============================================================
        stage('Docker Build') {
            steps {
                script {
                    sh '''
                        eval $(minikube -p minikube docker-env)
                        docker build -t $DOCKER_IMAGE:$DOCKER_TAG -f docker/Dockerfile .
                        docker tag $DOCKER_IMAGE:$DOCKER_TAG $DOCKER_IMAGE:latest
                    '''
                }
            }
        }

        // ============================================================
        // 7.5 SECURITE: VULNERABILITY SCAN (TRIVY)
        // ============================================================
        stage('Trivy Security Scan') {
            steps {
                script {
                    sh '''
                        eval $(minikube -p minikube docker-env)
                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.63.0 image --exit-code 1 --timeout 30m --severity HIGH,CRITICAL --no-progress --ignore-unfixed $DOCKER_IMAGE:$DOCKER_TAG
                    '''
                }
            }
        }

        // ============================================================
        // 8. DEPLOY SUR KUBERNETES (VIA HELM)
        // ============================================================
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    retry(3) {
                        sh '''
                            # Le fichier KUBECONFIG est automatiquement injecté par Jenkins via l'environnement
                            
                            # Assurez-vous que le namespace existe
                            kubectl create namespace $K8S_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
                            
                            # Déploiement avec Helm
                            helm upgrade --install student-management ./helm/student-management \\
                                --namespace $K8S_NAMESPACE \\
                                --set image.tag=$DOCKER_TAG \\
                                --set-string mysql.password="$MYSQL_PASSWORD" \\
                                --set-string mysql.rootPassword="$MYSQL_ROOT_PASSWORD" \\
                                --set-string grafana.adminPassword="$GRAFANA_ADMIN_PASSWORD" \\
                                --set-string app.security.password="$APP_SECURITY_PASSWORD" \\
                                --wait --atomic --timeout 10m
                            
                            # Attente du déploiement
                            kubectl rollout status deployment/spring-app -n $K8S_NAMESPACE --timeout=5m
                        '''
                    }
                }
            }
        }

        // ============================================================
        // 10. SMOKE TEST
        // ============================================================
        stage('Smoke Test') {
            steps {
                script {
                    retry(3) {
                        sh '''
                            sleep 10
                            # Test via Minikube IP et NodePort
                            MINIKUBE_IP=$(minikube ip)
                            curl -f -s -o /dev/null http://${MINIKUBE_IP}:30080/student/actuator/health || exit 1
                            echo "✅ Application OK"
                        '''
                    }
                }
            }
        }

        // ============================================================
        // 11. SUPERVISION (Prometheus/Grafana)
        // ============================================================
        stage('Monitoring') {
            steps {
                sh '''
                    # Les manifestes Prometheus et Grafana étaient appliqués via le dossier k8s/
                    # On ignore l'erreur s'ils ne sont pas déployés
                    kubectl rollout status deployment/prometheus -n ${K8S_NAMESPACE} || true
                    kubectl rollout status deployment/grafana -n ${K8S_NAMESPACE} || true
                '''
            }
        }
    }

    // ============================================================
    // POST-BUILD ACTIONS
    // ============================================================
    post {
        success {
            emailext (
                    subject: "✅ Pipeline SUCCESS - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    <h2>✅ Pipeline terminé avec succès !</h2>
                    <p><b>Projet:</b> ${env.JOB_NAME}</p>
                    <p><b>Build #:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p><b>Image Docker:</b> ${DOCKER_IMAGE}:${DOCKER_TAG}</p>
                    <p><b>Déployé sur:</b> Kubernetes (${K8S_NAMESPACE})</p>
                    <p><b>Application:</b> <a href="http://192.168.56.10:8089/student">http://192.168.56.10:8089/student</a></p>
                """,
                    to: "${MAIL_TO}",
                    from: "${MAIL_FROM}",
                    replyTo: "${MAIL_FROM}",
                    mimeType: 'text/html'
            )
        }
        failure {
            emailext (
                    subject: "❌ Pipeline FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    <h2 style="color: red;">❌ Pipeline échoué !</h2>
                    <p><b>Projet:</b> ${env.JOB_NAME}</p>
                    <p><b>Build #:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p><b>Erreur:</b> ${env.ERROR_MESSAGE}</p>
                    <p><b>Voir les logs:</b> ${env.BUILD_URL}/console</p>
                """,
                    to: "${MAIL_TO}",
                    from: "${MAIL_FROM}",
                    replyTo: "${MAIL_FROM}",
                    mimeType: 'text/html'
            )
        }
        always {
            script {
                sh '''
                    echo "🧹 Nettoyage Docker..."
                    eval $(minikube -p minikube docker-env)
                    # Supprimer les conteneurs arrêtés, les réseaux inutilisés et les images pendantes
                    docker system prune -f
                    # Supprimer les vieilles images de l'application pour libérer de l'espace
                    docker images "esprit/student-management" -q | tail -n +3 | xargs -r docker rmi -f || true
                '''
            }
            cleanWs()
        }
    }
}
