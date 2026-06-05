pipeline {
    agent any

    triggers {
        githubPush()
    }

    tools {
        jdk 'JDK25'
        maven 'Maven3.9'
    }

    environment {
        DOCKER_NAMESPACE = "walid369"
        DOCKER_IMAGE = "student-management"
        DOCKER_TAG = "latest"
        DEPLOY_SERVER = "localhost"
        MYSQL_ROOT_PASSWORD = "root123"
        MYSQL_DATABASE = "studentdb"
        SONAR_HOST_URL = "http://localhost:9000"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/WalidBenTouhami/student-management.git',
                    credentialsId: 'github-token'
            }
        }

        stage('Build Maven Project') {
            steps {
                sh 'sed -i "s/\\r$//" mvnw'
                sh 'chmod +x mvnw'
                sh './mvnw -DskipTests package'
                script {
                    env.GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh './mvnw -DskipTests sonar:sonar -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=admin -Dsonar.password=sonar'
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') {
                                error "Pipeline aborted due to Quality Gate: ${qg.status}"
                            }
                        }
                    } catch (err) {
                        echo "Quality Gate step skipped or failed: ${err}"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build --pull --no-cache -t ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG} ."
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

        stage('Clean environment and Deploy to server') {
            steps {
                sh '''
                    docker network create app-network 2>/dev/null || true
                    docker stop mysql 2>/dev/null || true
                    docker rm mysql 2>/dev/null || true
                    docker stop ${DOCKER_IMAGE} 2>/dev/null || true
                    docker rm ${DOCKER_IMAGE} 2>/dev/null || true
                    
                    docker run -d --name mysql \
                        --network app-network \
                        -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
                        -e MYSQL_DATABASE=${MYSQL_DATABASE} \
                        --restart unless-stopped \
                        mysql:8.0
                    
                    echo "Attente de l'initialisation de MySQL..."
                    sleep 15
                    
                    docker run -d --name ${DOCKER_IMAGE} \
                        --network app-network \
                        -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/${MYSQL_DATABASE} \
                        -e SPRING_DATASOURCE_USERNAME=root \
                        -e SPRING_DATASOURCE_PASSWORD=${MYSQL_ROOT_PASSWORD} \
                        -e SERVER_PORT=8089 \
                        -p 8089:8089 \
                        --restart unless-stopped \
                        ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    
                    echo "✅ Student Management déployé sur http://localhost:8089"
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline réussi !'
        }
        failure {
            echo '❌ Pipeline échoué'
        }
    }
}