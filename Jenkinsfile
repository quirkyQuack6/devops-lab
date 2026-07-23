def secrets = [
    [path: 'secret/homelab/db', engineVersion: 2, secretValues: [
        [envVar: 'VAULT_MYSQL_ROOT_PASS', vaultKey: 'mysql_root_password'],
        [envVar: 'VAULT_MYSQL_PASS', vaultKey: 'mysql_password'],
        [envVar: 'VAULT_MYSQL_USER', vaultKey: 'mysql_user'],
        [envVar: 'VAULT_MYSQL_EXP_USER', vaultKey: 'mysql_exp_user'],
        [envVar: 'VAULT_MYSQL_DATABASE', vaultKey: 'mysql_database'],
        [envVar: 'VAULT_TG_TOKEN', vaultKey: 'telegram_bot_token'],
        [envVar: 'VAULT_TG_CHAT', vaultKey: 'telegram_chat_id']
    ]],
    [path: 'secret/homelab/ci', engineVersion: 2, secretValues: [
        [envVar: 'VAULT_WPSCAN_API_TOKEN', vaultKey: 'WPSCAN_API_TOKEN']
    ]]
]

def configuration = [
  vaultUrl: 'http://localhost:8200', 
  vaultCredentialId: 'vault-root-token',
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
                sh "./scripts/syntaxcheck.sh"
            }
        }
   
        stage('Deploy Infrastructure Stack') {
            steps {
                echo 'Connecting to Vault and deploying via Ansible...'
                script {
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh "./scripts/deploy.sh"
                    }
                }
            }
        }

        stage('Start Test Environment') {
            steps {
                script {
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh "./scripts/test/start-test-env.sh"
                    }
                }
            }
        }
        
        stage('Initialize WordPress') {
            steps {
                script {
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh "./scripts/test/install-wordpress.sh"
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh "./scripts/test/run-wpscan.sh"
                    }
                }
                sh '''
                   docker create --name wpscan-copy \
                     -v test_wpscan_reports:/data \
                     alpine

                   docker cp wpscan-copy:/data/wpscan-report.json test/reports/wpscan-report.json
                   docker rm wpscan-copy
                   '''
                sh '''
                   echo "Reports:"
                   ls -lah test/reports
                   '''
            }
        }
    }

    post {

        always {
            archiveArtifacts( 
                artifacts: 'test/reports/*.json', 
                allowEmptyArchive: true
            )
        }

        success {
            echo 'CI/CD Pipeline completed successfully! Infrastructure is up-to-date.'
        }

        failure {
            echo 'Pipeline failed. Please check the logs above.'
        }

        cleanup {
            sh "./scripts/test/cleanup.sh"
        }
    }
}
