pipeline {
    agent none // 전체 파이프라인에 기본 에이전트를 설정하지 않고, 각 stage에서 사용할 에이전트를 지정
    
    environment {
        dockerHubRegistry = '78won96/docker-argocd'
        dockerHubRegistryCredential = 'Docker'
        githubCredential = 'github'
    }

    stages {
        stage('check out application git branch') {
            agent {
                label 'Pod-temp-ljw' // PodTemplate을 실행할 label 지정
            }
            steps {
                // GitHub에서 소스 코드 체크아웃
                checkout scm
            }
            post {
                success {
                    echo 'Repository checkout success'
                }
                failure {
                    echo 'Repository checkout failure'
                }
            }
        }

        stage('build gradle') {
            agent {
                label 'Pod-temp-ljw' // PodTemplate을 실행할 label 지정
            }
            steps {
                // Gradle 빌드 실행
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

        stage('docker image build') {
            agent {
                label 'Pod-temp-ljw' // PodTemplate을 실행할 label 지정
            }
            steps {
                // Docker 이미지 빌드
                sh "docker build . -t ${dockerHubRegistry}:${currentBuild.number}"
                sh "docker build . -t ${dockerHubRegistry}:latest"
            }
            post {
                success {
                    echo 'Docker image build success'
                }
                failure {
                    echo 'Docker image build failure'
                }
            }
        }

        stage('Docker Image Push') {
            agent {
                label 'Pod-temp-ljw' // PodTemplate을 실행할 label 지정
            }
            steps {
                // Docker 레지스트리에 이미지 푸시
                withDockerRegistry([ credentialsId: dockerHubRegistryCredential, url: "" ]) {
                    sh "docker push ${dockerHubRegistry}:${currentBuild.number}"
                    sh "docker push ${dockerHubRegistry}:latest"
                }
            }
            post {
                success {
                    echo 'Docker image push success'
                    sh "docker rmi ${dockerHubRegistry}:${currentBuild.number}"
                    sh "docker rmi ${dockerHubRegistry}:latest"
                }
                failure {
                    echo 'Docker image push failure'
                    sh "docker rmi ${dockerHubRegistry}:${currentBuild.number}"
                    sh "docker rmi ${dockerHubRegistry}:latest"
                }
            }
        }

        stage('K8S Manifest Update') {
            agent {
                label 'Pod-temp-ljw' // PodTemplate을 실행할 label 지정
            }
            steps {
                // GitOps Repo에 Kubernetes 매니페스트 업데이트
                sh 'mkdir -p gitOpsRepo'
                dir("gitOpsRepo") {
                    git branch: "main", credentialsId: githubCredential, url: 'https://github.com/78won96/gke-argocd-test.git'
                    
                    // Git 설정
                    sh "git config --global user.email 'juwon.lee@-infra.com'"
                    sh "git config --global user.name 'juwon.lee'"

                    // deployment.yaml 파일에서 Docker 이미지 버전 업데이트
                    sh "sed -i 's/docker:.*\$/docker:${currentBuild.number}/' deployment.yaml"
                    sh "git add deployment.yaml"
                    sh "git commit -m '[UPDATE] k8s ${currentBuild.number} image versioning'"

                    // GitHub에 변경 사항 푸시
                    withCredentials([gitUsernamePassword(credentialsId: githubCredential, gitToolName: 'git-tool')]) {
                        sh "git remote set-url origin https://github.com/78won96/argocd-manifests.git"
                        sh "git push -u origin main"
                    }
                }
            }
            post {
                success {
                    echo 'K8S Manifest Update success!'
                }
                failure {
                    echo 'K8S Manifest Update failure!'
                }
            }
        }
    }
    podTemplate(
        label: 'Pod-temp-ljw', // PodTemplate label을 지정하여 사용할 에이전트에 적용
        containers: [
            // Google Cloud SDK 컨테이너
            containerTemplate(name: "gcloud", image: "google/cloud-sdk:alpine", command: "cat", ttyEnabled: true, alwaysPullImage: true, resourceRequestCpu: '10m'),
            
            // Ubuntu 컨테이너
            containerTemplate(name: "ubuntu", image: "ubuntu", command: "cat", ttyEnabled: true, alwaysPullImage: true, resourceRequestCpu: '10m')
        ],
        volumes: [
            // Docker 소켓 마운트 (Docker 빌드를 위해 필요)
            hostPathVolume(mountPath: "/var/run/docker.sock", hostPath: "/var/run/docker.sock")
        ]
    )
}
