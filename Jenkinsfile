def envs
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
    // stage('Build') {
    //   steps {
    //     checkout scm
    //     sh "$WORKSPACE/build.sh ${env.GIT_COMMIT}"
    //   }
    // }
    stage('Deploy'){
      steps {
        ansiblePlaybook ('ping') {
          inventoryPath('files/ec2.py')
          tags('test2')
          credentialsId('credsid')
          become(true)
          becomeUser("user")
        }
      }
    }
  }
}