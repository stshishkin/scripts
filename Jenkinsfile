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
        // sh "$WORKSPACE/build.sh ${env.GIT_COMMIT}"
      }
    }
    stage('Deploy'){
      steps {
        ansiblePlaybook (
          playbook: "$WORKSPACE/deploy.yml",
          inventory: 'files/ec2.py',
          limit: "tag_Environment_${params.Envs}",
          credentialsId: 'credsid',
          extraVars: [
            rabbitmq_host: data[${params.Envs}].rabbitmq_host,
            rabbitmq_nodes: [data[${params.Envs}].rabbitmq_nodes],
            rabbitmq_port: "${rabbitmq_port}",
            rabbitmq_username: "${rabbitmq_port}",
            rabbitmq_password: "${rabbitmq_port}",
            redis_host: data[${params.Envs}].redis_host,
            redis_port: "${redis_port}",
            hyperion_type: "${hyperion_type}"
          ]
        )
      }
    }
  }
}