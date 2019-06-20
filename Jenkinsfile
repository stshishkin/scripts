def envs
node {
    dir('${JENKINS_HOME}/files/') {
        Envs = sh (script: 'python codio_envs.py', returnStdout: true).trim()
    }
}

pipeline {
    // a declarative pipeline
    agent any

    parameters {
            choice(name: 'Invoke_Parameters', choices:"Yes\nNo", description: "Do you whish to do a dry run to grab parameters?" )
            choice(name: 'Envs', choices:"${envs}", description: "")
    }
    stages {
        stage("parameterizing") {
            steps {
                script {
                    if ("${params.Invoke_Parameters}" == "Yes") {
                        currentBuild.result = 'ABORTED'
                        error('DRY RUN COMPLETED. JOB PARAMETERIZED.')
                    }
                }
            }
        }
        stage ("Check") {
            steps {
                echo "Selected env: ${params.Nodes}"
            }
        }
    }
 }