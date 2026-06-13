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
        DOCKER_NAMESPACE = "walid369"
        DOCKER_IMAGE = "student-management"
        DOCKER_TAG = "latest"
        DEPLOY_SERVER = "localhost"
        MYSQL_DATABASE = "studentdb"
        SONAR_HOST_URL = "http://localhost:9000"
        APP_CONTEXT_PATH = "/student"
        APP_PORT = "8089"
        CORS_ALLOWED_ORIGINS = "http://localhost:4200"
        SPRING_PROFILES_ACTIVE = "test"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/WalidBenTouhami/student-management.git',
                    credentialsId: 'github-token'
            }
        }

        stage('Build and Test') {
            steps {
                sh 'sed -i "s/\\r$//" mvnw'
                sh 'chmod +x mvnw'
                sh './mvnw clean verify -Dspring.profiles.active=test'
                script {
                    env.GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                }
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'Sonar_token', variable: 'SONAR_TOKEN')]) {
                    sh './mvnw sonar:sonar \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.login=${SONAR_TOKEN}'
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

        stage('Build Docker Image') {
            steps {
                sh "docker build --pull -t ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }

        stage('Docker Push to Registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin docker.io
                        docker push ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        if [ -n "${GIT_COMMIT}" ]; then
                            docker tag ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${GIT_COMMIT}
                            docker push ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${GIT_COMMIT}
                        fi
                        docker logout docker.io
                    '''
                }
            }
        }

        stage('Clean environment and Deploy') {
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
                    sh '''
                        docker network create app-network 2>/dev/null || true

                        docker stop mysql 2>/dev/null || true
                        docker rm mysql 2>/dev/null || true
                        docker stop ${DOCKER_IMAGE} 2>/dev/null || true
                        docker rm ${DOCKER_IMAGE} 2>/dev/null || true

                        # Start MySQL with a dedicated application user (least privilege)
                        docker run -d --name mysql \
                            --network app-network \
                            -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
                            -e MYSQL_DATABASE=${MYSQL_DATABASE} \
                            -e MYSQL_USER=${MYSQL_APP_USER} \
                            -e MYSQL_PASSWORD=${MYSQL_APP_PASSWORD} \
                            --health-cmd="mysqladmin ping -h localhost -uroot -p${MYSQL_ROOT_PASSWORD}" \
                            --health-interval=5s \
                            --health-timeout=5s \
                            --health-retries=12 \
                            --restart unless-stopped \
                            --memory=512m \
                            mysql:8.0

                        echo "Waiting for MySQL to be healthy..."
                        for i in $(seq 1 30); do
                            STATUS=$(docker inspect --format='{{.State.Health.Status}}' mysql 2>/dev/null)
                            if [ "$STATUS" = "healthy" ]; then
                                echo "✅ MySQL is ready."
                                break
                            fi
                            echo "  MySQL status: ${STATUS:-starting} (attempt $i/30)"
                            sleep 2
                        done

                        # Start application using the dedicated app user (not root)
                        docker run -d --name ${DOCKER_IMAGE} \
                            --network app-network \
                            -e SPRING_PROFILES_ACTIVE=prod \
                            -e SPRING_DATASOURCE_URL="jdbc:mysql://mysql:3306/${MYSQL_DATABASE}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" \
                            -e SPRING_DATASOURCE_USERNAME=${MYSQL_APP_USER} \
                            -e SPRING_DATASOURCE_PASSWORD=${MYSQL_APP_PASSWORD} \
                            -e ACTUATOR_USER=${ACTUATOR_USER} \
                            -e ACTUATOR_PASSWORD=${ACTUATOR_PASSWORD} \
                            -e API_USER=${API_USER} \
                            -e API_PASSWORD=${API_PASSWORD} \
                            -e API_SECURITY_ENABLED=true \
                            -e CORS_ALLOWED_ORIGINS=${CORS_ALLOWED_ORIGINS} \
                            -e SERVER_PORT=${APP_PORT} \
                            -p ${APP_PORT}:${APP_PORT} \
                            --restart unless-stopped \
                            --memory=512m \
                            ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}

                        echo "Waiting for application to start..."
                        for i in $(seq 1 30); do
                            if curl -sf -u "${ACTUATOR_USER}:${ACTUATOR_PASSWORD}" \
                                "http://localhost:${APP_PORT}${APP_CONTEXT_PATH}/actuator/health" \
                                | grep -q '"status":"UP"'; then
                                echo "✅ Student Management is UP on http://localhost:${APP_PORT}${APP_CONTEXT_PATH}"
                                break
                            fi
                            echo "  Waiting... ($i/30)"
                            sleep 2
                        done
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline succeeded.'
        }
        failure {
            echo '❌ Pipeline failed.'
        }
    }
}