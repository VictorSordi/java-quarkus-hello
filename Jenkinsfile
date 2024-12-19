pipeline {
    agent any

    environment {
        TAG = sh(script: 'git describe --abbrev=0',,returnStdout: true).trim()
    }

    stages {
        stage('Build with Maven') { 
            steps { 
                script { 
                    sh 'mvn clean package'
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
                    withCredentials([usernamePassword(credentialsId: 'nexus-user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]){
                        sh 'mvn deploy -DrepositoryId=jenkins -DaltDeploymentRepository=nexus::default::http://192.168.56.3:8091/repository/maven-releases/ -Dnexus.user=${USERNAME} -Dnexus.password=${PASSWORD}'
                    }
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