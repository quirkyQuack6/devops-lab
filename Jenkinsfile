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
    ]],
    [path: 'secret/homelab/test', engineVersion: 2, secretValues: [
        [envVar: 'VAULT_WP_ADMIN', vaultKey: 'wp_admin'],
        [envVar: 'VAULT_WP_ADMIN_PASS', vaultKey: 'wp_admin_pass'],
        [envVar: 'VAULT_WP_EMAIL', vaultKey: 'wp_email']
    ]],
    [path: 'secret/homelab/minio', engineVersion: 2, secretValues: [
        [envVar: 'AWS_ACCESS_KEY_ID', vaultKey: 'TERRAFORM_MINIO_ACCESS_KEY'],
        [envVar: 'AWS_SECRET_ACCESS_KEY', vaultKey: 'TERRAFORM_MINIO_SECRET_KEY']
    ]]
]

def configuration = [
  vaultUrl: 'http://localhost:8200', 
  vaultCredentialId: 'vault-root-token',
  engineVersion: 2
]

pipeline {
    agent any

    environment {
        ANSIBLE_PRIVATE_KEY_FILE = "/var/jenkins_home/.ssh/id_ed25519"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage( "Terraform Format" ) {
            steps {
                script {
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh "./scripts/terraform/fmt.sh"
                    }
                }
            }
        }

        stage("Terraform Init") {
            steps {
                script {
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh '''
                           echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
                           echo "SECRET_LENGTH=${#AWS_SECRET_ACCESS_KEY}"
                        '''
                        sh "./scripts/terraform/init.sh"
                    }
                }
            }
        }

        stage("Terraform Validate") {
            steps {
                script {
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh "./scripts/terraform/validate.sh"
                    }
                }
            }
        }

         stage("Terraform Plan") {
            steps {
                script {
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh "./scripts/terraform/plan.sh"
                    }
                }
            }
        }

         stage("Terraform Apply") {
            steps {
                script {
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh "./scripts/terraform/apply.sh"
                    }
                }
            }
        }

        stage('Ansible Validate') {
            steps {
                echo 'Checking Ansible Playbook syntax...'
                sh "./scripts/ansible/validate.sh"
            }
        }
   
        stage('Deploy Infrastructure Stack') {
            steps {
                echo 'Connecting to Vault and deploying via Ansible...'
                script {
                    withVault([configuration: configuration, vaultSecrets: secrets]) {
                        sh "./scripts/ansible/deploy.sh"
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
                sh "./scripts/test/copy-wpscan-report.sh"
                sh "./scripts/test/check-report.sh"
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
