pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven3.9'
    }

    environment {
        DOCKER_NAMESPACE = "walid369"
        DOCKER_IMAGE = "student-management"
        DOCKER_TAG = "latest"
        DEPLOY_SERVER = "localhost"
        MYSQL_ROOT_PASSWORD = "root123"
        MYSQL_DATABASE = "studentdb"
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
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG} ."
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
                        docker logout docker.io
                    '''
                }
            }
        }

        stage('Deploy to Server') {
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
                    
                    docker run -d --name ${DOCKER_IMAGE} \
                        --network app-network \
                        -p 8081:8080 \
                        --restart unless-stopped \
                        ${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    
                    echo "✅ Student Management déployé sur http://localhost:8081"
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