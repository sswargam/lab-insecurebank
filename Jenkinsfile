pipeline {
    agent any
    stages {
            stage('Checkout') {
            steps {
                git(url: 'https://github.com/devsecops-test/lab-insecurebank.git', branch: 'master')
                stash name:'Source', includes:'**/**'
                stash name:'dockerfile', includes: '**/Dockerfile'
            }
        }

        stage('Build') {
            agent {
                docker {
                    image 'maven:3.5.2-jdk-8'
                    args ' -v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                unstash 'Source'
                sh 'mvn clean package' 
                stash name:'WarFile', includes: '**/*.war' 
            }
        }
        
        stage('App Image Build and Test') {
            steps {
                script {
                    unstash 'dockerfile'
                    unstash 'WarFile'
                    sh 'cp target/*.war .'
                    
                    sh 'docker stop appcontainer || true && docker rm appcontainer || true'
                    docker.build('insecure-bank')
                    print 'App Image is built'
                    
                    //Test using Trivy
                    sh 'trivy image -f json -o trivy-results.json insecure-bank'
                    print 'App Image is tested'
                    archiveArtifacts '**/trivy-results.json'
                    recordIssues(tools: [trivy(pattern: 'trivy-results.json')])
                }
            }
        }

    
        stage('Deploy') {
            steps {
                script {
                    docker.image('insecure-bank').run('-d --name appcontainer -p 8085:8080')

                    sleep 45
                    sh 'wget http://localhost:8085/insecure-bank'
                    
                }
            }
        }
        
        stage('Test-Time DAST') {
            agent {
                docker {
                  image 'owasp/zap2docker-stable'
                  args '--network=host'
                   
                }
            }
            steps {
                script {
                    try {
                          sh 'zap-cli -p 2375 status -t 120 && zap-cli -p 2375 open-url http://localhost:8085/insecure-bank'
                          sh 'zap-cli -p 2375 spider http://localhost:8085/insecure-bank'
                          sh 'zap-cli -p 2375 active-scan -r http://localhost:8085/insecure-bank'
                          sh 'zap-cli -p 2375 report --output-format html --output owasp-zap.html'
                    
                          echo 'zap complete'
                          archiveArtifacts 'owasp-zap.html'
                          
                    } catch (err) {
                        echo "Caught: ${err}"
                    }
                } //end script
            } //end steps
        }

    }//stages

    post {
        always {
            sh 'docker stop appcontainer || true && docker rm appcontainer || true'
        }
    }

}//pipeline