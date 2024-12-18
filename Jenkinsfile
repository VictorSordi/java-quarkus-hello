pipeline {
    agent any

    environment {
        TAG = sh(script: 'git describe --abbrev=0',,returnStdout: true).trim()

        MVN_REPO_USER = credentials('nexus-username') 
        MVN_REPO_PASSWORD = credentials('nexus-password')
    }

    stages {
        stage('Build with Maven') { 
            steps { 
                script { 
                    sh 'mvn clean package'
                    sh 'mvn clean quarkus:build'
                } 
            } 
        }   

        stage('build docker image'){
        steps{
            sh 'docker build -t java-quarkus-hello/app:${TAG} .'
            }
        }
    
        stage ('deploy docker compose'){
        steps{
            sh 'docker compose up --build -d'
            }
        }

        stage('sleep for container deploy'){
        steps{
            sh 'sleep 10'
            }
        }

        stage('Sonarqube validation'){
            steps{
                script{
                    scannerHome = tool 'sonar-scanner';
                }
                withSonarQubeEnv('sonar-server'){
                    //sh "${scannerHome}/bin/sonar-scanner mvn clean install sonar:sonar -Dsonar.projectKey=java-hello -Dsonar.sources=src/main/java/ -Dsonar.java.binaries=target/classes  -Dsonar.host.url=${env.SONAR_HOST_URL} -Dsonar.token=${env.SONAR_AUTH_TOKEN} -X"
                    sh "mvn clean install sonar:sonar -Dsonar.projectKey=java-quarkus-hello -Dsonar.sources=src/main/java/ -Dsonar.java.binaries=target/classes  -Dsonar.host.url=${env.SONAR_HOST_URL} -Dsonar.token=${env.SONAR_AUTH_TOKEN} -X"
                }
                sh 'sleep 10'
            }
        }

        stage("Quality Gate"){
            steps{
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Shutdown docker containers') {
            steps{
                sh 'docker compose down'
            }
        }

        stage('Deploy to Nexus') { 
            steps { 
                script {
                    withCredentials([usernamePassword(credentialsId: 'nexus-user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')])
                    sh """
                    mvn deploy \ 
                        -DaltDeploymentRepository=nexus::default::${NEXUS_URL}/repository/maven-releases/ \ 
                        -Dusername=$USERNAME \ 
                        -Dpassword=$PASSWORD 
                    """
                } 
            } 
        }

        stage('Upload docker image'){
            steps{
                script {
                    withCredentials([usernamePassword(credentialsId: 'nexus-user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh 'docker login -u $USERNAME -p $PASSWORD ${NEXUS_URL}'
                        sh 'docker tag java-quarkus-hello/app:${TAG} ${NEXUS_URL}/java-quarkus-hello/app:${TAG}'
                        sh 'docker push ${NEXUS_URL}/java-quarkus-hello/app:${TAG}'
                        //sh 'docker tag $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG $NEXUS_URL/repository/$NEXUS_REPO/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG' 
                        //sh 'docker push $NEXUS_URL/repository/$NEXUS_REPO/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG' 
                    }
                }
            }
        }

        stage("Apply kubernetes files"){
            steps{
                sh '/usr/local/bin/kubectl apply -f ./kubernetes/java-quarkus-hello.yaml'
            }
        }
    }
}