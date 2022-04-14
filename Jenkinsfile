pipeline {
    agent any 
    stages {       
            stage('Checkout'){
            steps {
                git(url: 'https://github.com/snehakokil/insecurebank.git', branch: 'master')
                stash name:'Source', includes:'**/**'
                stash name:'dockerfile', includes: '**/Dockerfile'
                
            }
        }
    
        stage('Commit-Time SAST') {
            agent { 
                docker { 
                    image 'maven:3.5.2-jdk-8'
                    args ' -v $HOME/.m2:/root/.m2'
                    
                } 
            }
            steps {
                script {
                    unstash 'Source'
                    def isSuccess = sh label: '', returnStatus: true, script: 'mvn clean compile spotbugs:check'
                    if(isSuccess > 0) {
                        input 'SAST found bugs in the source code. Do you want to proceed?'
                    }
                        stash name:'CompiledSource', includes: '**/**'
                        archiveArtifacts '**/spotbugsXml.xml'
                        recordIssues(tools: [spotBugs(pattern: '**/spotbugsXml.xml', useRankAsPriority: true)])
               }
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
        
        stage('Build-Time SCA') {
            steps {
                unstash 'WarFile'
                dependencyCheck additionalArguments: '', odcInstallation: 'dependency-check'
                archiveArtifacts '**/dependency-check-report.xml'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }            
        }
        stage('App Image Build and Test') {
            steps {
                script {
                    unstash 'dockerfile'
                    unstash 'WarFile'
                    sh 'cp target/*.war .'
                    
                    docker.build('insecurebank:latest')
                    print 'App Image is built'
                    
		    //Test using Trivy
                    try {
                        sh 'trivy image -o trivy-results.txt --exit-code 1 insecurebank:latest'
                        //sh 'trivy image -f json -o trivy-results.json --exit-code=1 insecurebank:latest'
                    } 
                    catch(err) {
                        input 'Docker image is non-compliant. Do you want to proceed?'
                    }                
                    archiveArtifacts '**/trivy-results.txt'
                }
            }
        }        
        stage('Deploy') {
            steps {
                script {
                    docker.image('insecurebank:latest').run('-d --name appcontainer -p 8181:8080')
                
                    sleep 45
                    sh 'wget http://localhost:8181/insecure-bank'
                    
                }
            }
        }
        
        stage('Test-Time DAST'){
            agent {
                docker {
                  image 'owasp/zap2docker-stable'
                  args '--network=host'
                   
                  }
                }
            steps {
                script{
                    try {
                          //sh 'zap.sh -daemon -port 2375 -host 127.0.0.1 -config api.disablekey=true -config scanner.attackOnStart=true -config view.mode=attack -config connection.dnsTtlSuccessfulQueries=-1 -config api.addrs.addr.name=.* -config api.addrs.addr.regex=true &'
                          sh 'zap-cli -p 2375 status -t 120 && zap-cli -p 2375 open-url http://localhost:8181/insecure-bank'
                          sh 'zap-cli -p 2375 spider http://localhost:8181/insecure-bank'
                          sh 'zap-cli -p 2375 active-scan -r http://localhost:8181/insecure-bank'
                          sh 'zap-cli -p 2375 report --output-format html --output owasp-zap.html'
                          //sh 'zap-cli -p 8090 -v quick-scan -sc -o \'-config api.disablekey=true\' http://localhost:8082/ | tee zap.txt'
                          
                          echo 'zap complete'
                          archiveArtifacts 'owasp-zap.html'
                          
                    }
                    catch (err) {
                        echo "Caught: ${err}"
                    }
                } //end script
            } //end steps
        }
        
        stage('Clean Up') {
            steps {
                script {
                    sh 'docker stop appcontainer'
                    sh 'docker rm appcontainer'
                }
            }
        }

    }//stages

}//pipeline
