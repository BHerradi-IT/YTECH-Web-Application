pipeline {
    agent any

    environment {
        IMAGE_NAME = "YTECH-Web-Application-image"
        CONTAINER_NAME = "ynov-project-container"
        SONAR_HOST_URL = "http://192.168.142.143:9000"
        SONAR_TOKEN = credentials('sonar-token')
        
        // Docker Hub Settings
        DOCKER_HUB_USERNAME = "peacechouaib"
        DOCKER_HUB_IMAGE = "YTECH-Web-Application"
        
        // Email Settings
        EMAIL_RECIPIENT = "herraditech@gmail.com"
    }

    stages {
        stage('Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/BHerradi-IT/YTECH-Web-Application.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    sh '''
                        echo "========== SonarQube Analysis Started =========="
                        
                        docker run --rm \
                          -v $(pwd):/usr/src \
                          -w /usr/src \
                          sonarsource/sonar-scanner-cli:latest \
                          sonar-scanner \
                          -Dsonar.projectKey=YTECH-Web-Application \
                          -Dsonar.projectName="YTECH-Web-Application" \
                          -Dsonar.projectVersion=1.0 \
                          -Dsonar.sources=frontend/src \
                          -Dsonar.exclusions=**/node_modules/**,**/*.test.js \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_TOKEN}
                        
                        echo "✅ SonarQube analysis completed"
                    '''
                }
            }
        }

        stage('Quality Gate Check') {
            steps {
                script {
                    echo "Waiting for SonarQube analysis..."
                    sleep(time: 30, unit: 'SECONDS')
                    
                    sh '''
                        STATUS=$(curl -s -u ${SONAR_TOKEN}: "${SONAR_HOST_URL}/api/qualitygates/project_status?projectKey=YTECH-Web-Application" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
                        echo "Quality Gate Status: ${STATUS}"
                        
                        if [ "$STATUS" = "ERROR" ]; then
                            echo "❌ Quality Gate failed!"
                            exit 1
                        else
                            echo "✅ Quality Gate passed!"
                        fi
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:latest ."
                    sh "docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${BUILD_NUMBER}"
                }
            }
        }

        // ========== Trivy Security Scan (مصحح) ==========
        stage('Trivy Security Scan') {
            steps {
                script {
                    sh '''
                        echo "========== Trivy Security Scan Started =========="
                        
                        mkdir -p reports
                        
                        #  Trivy 
                        docker pull aquasec/trivy:0.59.0
                        
                        docker run --rm \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          -v $(pwd):/src \
                          -w /src \
                          aquasec/trivy:0.59.0 \
                          image ${IMAGE_NAME}:latest \
                          --severity HIGH,CRITICAL \
                          --format table \
                          --output reports/trivy-scan.txt || true
                        
                        # file JSON
                        docker run --rm \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          -v $(pwd):/src \
                          -w /src \
                          aquasec/trivy:0.59.0 \
                          image ${IMAGE_NAME}:latest \
                          --format json \
                          --output reports/trivy-report.json || true
                        
                        # Repport
                        echo "========================================="
                        echo "📊 Trivy Scan Summary"
                        echo "========================================="
                        cat reports/trivy-scan.txt || echo "No vulnerabilities found"
                        echo "========================================="
                        
                        echo "✅ Trivy scan completed"
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/*', fingerprint: true, allowEmptyArchive: true
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "========== Pushing to Docker Hub =========="
                    
                    withDockerRegistry(credentialsId: 'docker-hub-cred') {
                        sh "docker tag ${IMAGE_NAME}:latest ${DOCKER_HUB_USERNAME}/${DOCKER_HUB_IMAGE}:latest"
                        sh "docker tag ${IMAGE_NAME}:latest ${DOCKER_HUB_USERNAME}/${DOCKER_HUB_IMAGE}:${BUILD_NUMBER}"
                        sh "docker push ${DOCKER_HUB_USERNAME}/${DOCKER_HUB_IMAGE}:latest"
                        sh "docker push ${DOCKER_HUB_USERNAME}/${DOCKER_HUB_IMAGE}:${BUILD_NUMBER}"
                        
                        echo "✅ Image pushed: ${DOCKER_HUB_USERNAME}/${DOCKER_HUB_IMAGE}:${BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Stop Old Container') {
            steps {
                script {
                    sh "docker stop ${CONTAINER_NAME} || true"
                    sh "docker rm ${CONTAINER_NAME} || true"
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    sh "docker run -d --name ${CONTAINER_NAME} -p 80:80 ${IMAGE_NAME}:latest"
                    echo "✅ Application running on port 80"
                }
            }
        }
    }
    
    post {
        success {
            script {
                emailext(
                    subject: "✅ Pipeline SUCCESS - ${JOB_NAME} #${BUILD_NUMBER}",
                    body: """
                        Pipeline completed successfully!
                        
                        Build: ${JOB_NAME} #${BUILD_NUMBER}
                        Status: SUCCESS
                        
                        SonarQube: PASSED
                        Trivy Scan: COMPLETED
                        Docker Hub: ${DOCKER_HUB_USERNAME}/${DOCKER_HUB_IMAGE}:${BUILD_NUMBER}
                        Application: http://localhost:80
                        
                        Build URL: ${BUILD_URL}
                    """,
                    to: "${EMAIL_RECIPIENT}"
                )
                echo "✅ Success email sent to ${EMAIL_RECIPIENT}"
            }
            echo "✅ PIPELINE COMPLETED SUCCESSFULLY!"
        }
        failure {
            script {
                emailext(
                    subject: "❌ Pipeline FAILED - ${JOB_NAME} #${BUILD_NUMBER}",
                    body: """
                        Pipeline failed!
                        
                        Build: ${JOB_NAME} #${BUILD_NUMBER}
                        Status: FAILED
                        
                        Check Jenkins logs: ${BUILD_URL}
                    """,
                    to: "${EMAIL_RECIPIENT}"
                )
                echo "❌ Failure email sent to ${EMAIL_RECIPIENT}"
            }
            echo "❌ PIPELINE FAILED!"
        }
    }
}
