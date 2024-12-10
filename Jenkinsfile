pipeline {
    agent {
        kubernetes {
            label 'test-scan'  // 파드 레이블
            defaultContainer 'gcloud'  // 기본 컨테이너 설정
            containerTemplate(name: 'gcloud', image: 'google/cloud-sdk:alpine', ttyEnabled: true, alwaysPullImage: true)
            volumes: [
                hostPathVolume(mountPath: "/var/run/docker.sock", hostPath: "/var/run/docker.sock") // Docker 소켓 공유
            ]
        }
    }

 

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
        stage('Prisma Cloud Image Scan') { // See 6
            steps {
                script{
                    prismaCloudScanImage (   
                    ca: '',
                    cert: '',
                    containerized:true,
                    image: "${dockerHubRegistry}:${currentBuild.number}", 
                    dockerAddress: 'unix:///var/run/docker.sock',
                    project: '',
                    ignoreImageBuildTime: true,
                    key: '',
                    logLevel: 'info',
                    podmanPath: '',
                    resultsFile: 'prisma-cloud-scan-results.json' 
                    )
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
                    sh "sed -i 's/docker-argocd:.*\$/docker-argocd:${currentBuild.number}/' deployment.yaml"
                    sh "git add ."
                    sh "git commit -m '[UPDATE] k8s ${currentBuild.number} image versioning'"

                    withCredentials([gitUsernamePassword(credentialsId: githubCredential, gitToolName: 'default')]) {
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