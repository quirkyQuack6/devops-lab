pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Lint & Validate') {
            steps {
                echo 'Checking Ansible Playbook syntax...'
                sh 'ansible-playbook -i ansible/hosts.ini ansible/playbook.yml --syntax-check'
            }
        }

        stage('Deploy Infrastructure Stack') {
            steps {
                echo 'Deploying Docker Compose stack to KVM via Ansible...'
                sh 'ansible-playbook -i ansible/hosts.ini ansible/playbook.yml'
            }
        }
    }

    post {
        success {
            echo 'CI/CD Pipeline completed successfully! Infrastructure is up-to-date.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs above.'
        }
    }
}
