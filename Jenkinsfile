def listEnvs() {
    def sout = new StringBuffer(), serr = new StringBuffer()
    def proc = 'python ${JENKINS_HOME}/files/codio_envs.py'.execute()
    proc.consumeProcessOutput(sout, serr)
    proc.waitForOrKill(10000)
    return sout.tokenize() 
}

def Envs = listEnvs().join('\n')

pipeline {
    // a declarative pipeline
    agent any

    parameters {
        choice(name: 'Release',
               choices: Envs)
    }
    stages {
        stage("Init") {
            agent any
            steps { listEnvs() }
        }
    }
 }
