pipeline {
    agent any
    
    environment {
        dockerHubRegistry = '78won96/docker-argocd'
        dockerHubRegistryCredential = 'Docker'
        githubCredential = 'github'
    }

    stages {
        stage('Check out application git branch') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/78won96/gke-argocd-test.git',
                    credentialsId: githubCredential
            }
            post {
                failure {
                    echo 'Repository checkout failure'
                }
                success {
                    echo 'Repository checkout success'
                }
            }
        }
        stage('Build gradle') {
            steps {
                sh 'chmod +x ./gradlew || true'  // 루트 권한이 이미 주어졌으므로 오류 방지
                sh './gradlew build'
                sh 'ls -al ./build'
            }
            post {
                success {
                    echo 'Gradle build success'
                }
                failure {
                    echo 'Gradle build failed'
                }
            }
        }
        stage('Docker image build') {
            steps {
                container('docker') {
                    sh "docker build . -t ${dockerHubRegistry}:${currentBuild.number}"
                    sh "docker build . -t ${dockerHubRegistry}:latest"
                }
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
        stage('Docker Image Push') {
            steps {
                container('docker') {
                    withDockerRegistry([credentialsId: dockerHubRegistryCredential, url: ""]) {
                        sh "docker push ${dockerHubRegistry}:${currentBuild.number}"
                        sh "docker push ${dockerHubRegistry}:latest"
                    }
                }
            }
            post {
                failure {
                    echo 'Docker Image Push failure !'
                }
                success {
                    echo 'Docker image push success !'
                }
            }
        }
        stage('K8S Manifest Update') {
            steps {
                dir('gitOpsRepo') {
                    git branch: 'main',
                        credentialsId: githubCredential,
                        url: 'https://github.com/78won96/argocd-manifests.git'
                    sh "git config --global user.email 'juwon.lee@u-infra.com'"
                    sh "git config --global user.name 'juwon.lee'"
                    sh "sed -i 's/docker:.*\$/docker:${currentBuild.number}/' deployment.yaml"
                    sh "git add deployment.yaml"
                    sh "git commit -m '[UPDATE] k8s ${currentBuild.number} image versioning'"
                    withCredentials([gitUsernamePassword(credentialsId: githubCredential, gitToolName: 'git-tool')]) {
                        sh "git remote set-url origin https://github.com/78won96/argocd-manifests.git"
                        sh "git push -u origin main"
                    }
                }
            }
            post {
                failure {
                    echo 'K8S Manifest Update failure !'
                }
                success {
                    echo 'K8S Manifest Update success !'
                }
            }
        }
    }
}