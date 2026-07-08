def secrets = [
    [path: 'secret/homelab/db', engineVersion: 2, secretValues: [
        [envVar: 'VAULT_MYSQL_ROOT_PASS', vaultKey: 'mysql_root_password'],
        [envVar: 'VAULT_MYSQL_PASS', vaultKey: 'mysql_password'],
        [envVar: 'VAULT_MYSQL_USER', vaultKey: 'mysql_user'],
        [envVar: 'VAULT_MYSQL_EXPORTER_USER', vaultKey: 'mysql_exporter_user'],
        [envVar: 'VAULT_MYSQL_DATABASE', vaultKey: 'mysql_database']
    ]]
]

def configuration = [
  vaultUrl: 'http://localhost:8200', 
  engineVersion: 2
]

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
                echo 'Connecting to Vault and deploying via Ansible...'
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                    sh "ansible-playbook -i ansible/hosts.ini ansible/playbook.yml --extra-vars 'mysql_root_password=${env.VAULT_MYSQL_ROOT_PASS} mysql_password=${env.VAULT_MYSQL_PASS} mysql_user=${env.VAULT_MYSQL_USER} mysql_exporter_user=${env.MYSQL_EXPORTER_USER} mysql_database=${env.VAULT_MYSQL_DATABASE}'"
                }
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
