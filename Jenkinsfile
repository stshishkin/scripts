def listEnvs() {
    def sout = new StringBuffer(), serr = new StringBuffer()
    def proc = 'python ${JENKINS_HOME}/files/codio_envs.py'.execute()
    proc.consumeProcessOutput(sout, serr)
    proc.waitForOrKill(10000)
    return sout.tokenize() 
}

def Envs = listEnvs().join('\n')

pipeline {
    agent any
    stages {
        stage ("Init") {
            steps { 
                def ENVS = listEnvs() 
                inputResult = input(
                    message: "Select env",
                    parameters: [
                        choise (
                            name: "envs",
                            choices: "${ENVS}",
                            description: "Env" 
                            )
                    ]
                )
            }
        }
        stage ("Check") {
            steps {
                echo "Selected env: ${inputResult}"
            }
        }
    }
 }
