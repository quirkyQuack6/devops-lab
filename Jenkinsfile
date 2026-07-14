def secrets = [
    [path: 'secret/homelab/db', engineVersion: 2, secretValues: [
        [envVar: 'VAULT_MYSQL_ROOT_PASS', vaultKey: 'mysql_root_password'],
        [envVar: 'VAULT_MYSQL_PASS', vaultKey: 'mysql_password'],
        [envVar: 'VAULT_MYSQL_USER', vaultKey: 'mysql_user'],
        [envVar: 'VAULT_MYSQL_EXP_USER', vaultKey: 'mysql_exp_user'],
        [envVar: 'VAULT_MYSQL_DATABASE', vaultKey: 'mysql_database'],
        [envVar: 'VAULT_TG_TOKEN', vaultKey: 'telegram_bot_token'],
        [envVar: 'VAULT_TG_CHAT', vaultKey: 'telegram_chat_id']
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
                sh 'ansible-playbook -i ansible/hosts.ini ansible/playbook.yml --syntax-check'
            }
        }

        stage('Deploy Infrastructure Stack') {
            steps {
                echo 'Connecting to Vault and deploying via Ansible...'
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                    sh "ansible-playbook -i ansible/hosts.ini ansible/playbook.yml --extra-vars 'mysql_root_password=${env.VAULT_MYSQL_ROOT_PASS} mysql_password=${env.VAULT_MYSQL_PASS} mysql_user=${env.VAULT_MYSQL_USER} mysql_exp_user=${env.VAULT_MYSQL_EXP_USER} mysql_database=${env.VAULT_MYSQL_DATABASE} telegram_bot_token=${env.VAULT_TG_TOKEN} telegram_chat_id=${env.VAULT_TG_CHAT}'"
                }
            }
        }

        stage('Security Scan: WPScan') {
            steps {
                echo 'Starting WPScan....'
                sh '''
                    docker run --rm \
                    --network host \
                    -v "$PWD:/work" \
                    -w /work \
                    wpscanteam/wpscan \
                    --url http://192.168.122.204:8000 \
                    --enumerate vp,vt,u \
                    --format json \
                    -o wpscan-report.json
                   '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'wpscan-report.json', fingerprint: true
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
