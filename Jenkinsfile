pipeline {
    agent any



    environment {
        APP_ENV = "DEV"
        DOCKER_REGISTRY = "docker.io"
        DOCKER_IMAGE = "esprit/student-management"
        DOCKER_TAG = "${env.BUILD_ID}"
        K8S_NAMESPACE = "devops-tools"
        SONAR_HOST_URL = "http://192.168.56.10:9000"
    }

    stages {
        // ============================================================
        // 1. CHECKOUT DU CODE
        // ============================================================
        stage('Checkout') {
            steps {
                checkout scmGit(
                        branches: [[name: '*/main']],
                        userRemoteConfigs: [[
                                                    url: 'https://github.com/WalidBenTouhami/student-management.git',
                                                    credentialsId: 'github-credentials'
                                            ]]
                )
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
        stage('Test') {
            steps {
                sh 'chmod +x mvnw && ./mvnw clean test jacoco:report'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        // ============================================================
        // 4. ANALYSE SONARQUBE
        // ============================================================
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "chmod +x mvnw && ./mvnw sonar:sonar -Dsonar.projectKey=student-management-pipeline -Dsonar.projectName='Student Management Pipeline' -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.token=sqa_8186ec2bc2572e08ad1a14abb33e5c2b734a033e -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml"
                }
            }
        }

        // ============================================================
        // 5. QUALITY GATE (Désactivé temporairement)
        // ============================================================
        // stage('Quality Gate') {
        //     steps {
        //         timeout(time: 1, unit: 'HOURS') {
        //             waitForQualityGate abortPipeline: false
        //         }
        //     }
        // }

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
                    sh """
                        eval \$(minikube -p minikube docker-env)
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -f docker/Dockerfile .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        // ============================================================
        // 7.5 SECURITE: VULNERABILITY SCAN (TRIVY)
        // ============================================================
        stage('Trivy Security Scan') {
            steps {
                script {
                    sh """
                        eval \$(minikube -p minikube docker-env)
                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --timeout 30m --severity HIGH,CRITICAL --no-progress --ignore-unfixed ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                    """
                }
            }
        }

        // ============================================================
        // 8. DEPLOY SUR KUBERNETES (VIA HELM)
        // ============================================================
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh """
                        # Assurez-vous que le namespace existe
                        kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                        
                        # Déploiement avec Helm
                        helm upgrade --install student-management ./helm/student-management \\
                            --namespace ${K8S_NAMESPACE} \\
                            --set image.tag=${DOCKER_TAG}
                        
                        # Attente du déploiement
                        kubectl rollout status deployment/spring-app -n ${K8S_NAMESPACE}
                    """
                }
            }
        }

        // ============================================================
        // 10. SMOKE TEST
        // ============================================================
        stage('Smoke Test') {
            steps {
                sh '''
                    sleep 10
                    # Test via Minikube IP et NodePort
                    MINIKUBE_IP=$(minikube ip)
                    curl -f http://${MINIKUBE_IP}:30080/student/actuator/health || exit 1
                '''
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
                    to: 'walid.bentouhami@esprit.tn'
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
                    to: 'walid.bentouhami@esprit.tn'
            )
        }
        always {
            cleanWs()
            script {
                sh '''
                    echo "Nettoyage de l'espace Docker dans Minikube..."
                    eval $(minikube -p minikube docker-env)
                    # Supprimer les conteneurs arrêtés, les réseaux inutilisés et les images pendantes
                    docker system prune -f
                    # Supprimer les vieilles images de l'application pour libérer de l'espace
                    docker images "esprit/student-management" -q | tail -n +3 | xargs -r docker rmi -f || true
                '''
            }
        }
    }
}