pipeline {
    agent any
    tools{
        maven "Maven3.9.6"
    }
    stages {
      stage('Clone the repository'){
        steps{
          git branch: 'pushing-docker-image-to-ecr-jenkinsfile',
                    credentialsId: '2061094a-46a6-4f96-966e-97fdecb8ca93',
                    url: 'https://github.com/sreddy9291/java-application.git'
        } 
      }
      
  stage('Build the code') {
            steps {
                sh 'mvn clean install'
            }
        }    
      
   stage('Build Docker Image') {
            steps {
                sh '''
              docker build . --tag web-application:$BUILD_NUMBER
              docker tag web-application:$BUILD_NUMBER 024358826974.dkr.ecr.us-east-1.amazonaws.com/web-application:$BUILD_NUMBER
                
                '''
                
            }
        }  
      
    }
}
