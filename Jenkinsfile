def envs
def data = [
  production: [
    rabbitmq_host: "rabbitmq.int.codio.com",
    rabbitmq_nodes: [
      "worker1.int.codio.com",
      "worker2.int.codio.com"
    ],
    redis_host: "redis.int.codio.com"
  ],
  production_eu: [
    rabbitmq_host: "rabbitmq.int.codio.co.uk",
    rabbitmq_nodes: [
      "worker1.int.codio.co.uk",
      "worker2.int.codio.co.uk"
    ],
    redis_host: "redis.int.codio.co.uk"
  ],
  test1: [
    rabbitmq_host: "rabbitmq-${params.Envs}.int.codio.com",
    rabbitmq_nodes: [
      "rabbitmq-${params.Envs}.int.codio.com"
    ],
    redis_host: "redis-${params.Envs}.int.codio.com"
  ],
  test2: [
    rabbitmq_host: "rabbitmq-${params.Envs}.int.codio.com",
    rabbitmq_nodes: [
      "rabbitmq-${params.Envs}.int.codio.com"
    ],
    redis_host: "redis-${params.Envs}.int.codio.com"
  ],
  staging: [
    rabbitmq_host: "rabbitmq-${params.Envs}.int.codio.com",
    rabbitmq_nodes: [
      "worker21-staging.int.codio.com"
    ],
    redis_host: "redis-${params.Envs}.int.codio.com"
  ]
]

node {
    dir('${JENKINS_HOME}/files/') {
        envs = sh (script: 'python /var/jenkins_home/files/ec2.py | grep -Po \'(?<="tag_Environment_).*(?=":)\'', returnStdout: true).trim()
    }
}

pipeline {
  agent any
  parameters {
    choice(name: 'Invoke_Parameters', choices: '''Yes\nNo''', description: 'Do you whish to do a dry run to grab parameters?')
    choice(name: 'Envs', choices: "${envs}", description: '')
  }
  stages {
    stage('parameterizing') {
      steps {
        script {
          if ("${params.Invoke_Parameters}" == "Yes") {
            currentBuild.result = 'ABORTED'
            error('DRY RUN COMPLETED. JOB PARAMETERIZED.')
          }
        }

      }
    }
    stage('Check') {
      steps {
        echo "Selected env: ${params.Envs}"
      }
    }
    stage('Build') {
      steps {
        checkout scm
        sh "$WORKSPACE/build.sh ${env.GIT_COMMIT}"
      }
    }
    stage('Deploy'){
      steps {
        ansiblePlaybook ("$WORKSPACE/deploy.yml") {
          inventoryPath('files/ec2.py')
          tags('test2')
          credentialsId('credsid')
          extraVars {
            extraVar('rabbitmq_host',"${data[${params.Envs}].rabbitmq_host}",false)
            extraVar('rabbitmq_nodes',"[${data[${params.Envs}].rabbitmq_nodes}]",false) // check
            extraVar('rabbitmq_port',"${rabbitmq_port}",false)
            extraVar('rabbitmq_username',"${rabbitmq_port}",false)
            extraVar('rabbitmq_password',"${rabbitmq_port}",false)

            extraVar('redis_host',"${data[${params.Envs}].redis_host}",false)
            extraVar('redis_port',"${redis_port}",false)

            extraVar('hyperion_type',"${hyperion_type}",false)
          }

        }
      }
    }
  }
}