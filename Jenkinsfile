pipeline {
  agent any
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
        echo "Selected env: ${params.Nodes}"
      }
    }
  }
  parameters {
    choice(name: 'Invoke_Parameters', choices: '''Yes
No''', description: 'Do you whish to do a dry run to grab parameters?')
    choice(name: 'Envs', choices: "${envs}", description: '')
  }
}