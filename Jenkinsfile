pipeline {
    agent any
    environment {
        dockerHubRegistry = 'dongjukim123/ci-cd'
        dockerHubRegistryCredential = 'docker-hub' // docker credential 에서 생성한 ID값
        githubCredential = 'kdj-8596-cred1' // github credential 에서 생성한 ID값
    }
    // 1. git repository 가 체크되는지 확인, 제대로 연동이 안될 경우, 이 단계(stage) 에서 fail 발생
    stages {
        stage('check out application git branch') {
            steps {
                checkout scm
            }
            post {
                failure {
                    echo 'repository checkout failure'
                }
                success {
                    echo 'repository checkout success'
                }
            }
        }
        // 2. gradle 빌드 (springboot web 생성을 위한 선행과정)
        stage('build gradle') {
            steps {
                sh './gradlew build'
                sh 'ls -al ./build'
            }
            post {
                success {
                    echo 'gradle build success'
                }
                failure {
                    echo 'gradle build failed'
                }
            }
        }
        // 3. Dockefile build 
        stage('docker image build') {
            steps {
                sh "docker build . -t ${dockerHubRegistry}:${currentBuild.number}"
                sh "docker build . -t ${dockerHubRegistry}:latest"
            }
            post {
                failure {
                    echo 'Docker image build failure !'
                }
                success {
                    echo 'Docker image build success !'
                }
            }
        }
        // 4. 빌드된 이미지 push 
        stage('Docker Image Push') {
            steps {
                withDockerRegistry([ credentialsId: dockerHubRegistryCredential, url: "" ]) {
                    sh "docker push ${dockerHubRegistry}:${currentBuild.number}"
                    sh "docker push ${dockerHubRegistry}:latest"
                    sleep 10 /* Wait uploading */
                }
            }
            post {
                failure {
                    echo 'Docker Image Push failure !'
                    sh "docker rmi ${dockerHubRegistry}:${currentBuild.number}"
                    sh "docker rmi ${dockerHubRegistry}:latest"
                }
                success {
                    echo 'Docker image push success !'
                    sh "docker rmi ${dockerHubRegistry}:${currentBuild.number}"
                    sh "docker rmi ${dockerHubRegistry}:latest"
                }
            }
        }
    }
}
