# cogsi2526-1221322-1201623-1151352

## Self-evaluation

# TODO

Santiago -
Rafael -
Joao -

## Part 1

### 1 - Analysis / Requirements

The first part of CA6 consists of creating a Jenkins pipeline that automates the build, test, and deployment of the “Building REST services with Spring” application (Gradle version) to local virtual machines, following a structure similar to CA3 Part 1 (using vagrant).

### 1.1 Infrastructure
- Create two VMs (blue and green) using Vagrant
- Provision the VMs with Ansible
- Initial deployment on the blue VM
- Application and H2 database run on the same VM

### 1.2 Jenkins Pipeline
The pipeline must include the following stages:
- Checkout: Get code from the development branch
- Assemble: Compile and produce artifacts
- Test: Run unit tests and publish results
- Archive: Archive artifacts in Jenkins
- Deploy to Production?: Manual approval for deployment
- Deploy: Deployment on the green VM via Ansible playbook

### 1.3 Tagging and Versioning
- Apply tags to stable builds (e.g., stable-v1.0, stable-v1.1) and only on artifacts that pass all tests

### 1.4 Post-Actions
- Notification: Message with execution result
- Deployment Verification: Automatic health checks after deployment

### 1.5 Rollback green VM
- Create Ansible playbook for rollback that:
- Obtains stable artifact from Jenkins via API/CLI
- Replaces with stable artifact
- Restarts service
- Performs verification health checks

### 2 - Design of the solution
The application will have the following files (which will be explained later):

    CA6/Part1
    |__ inventory.ini
    |__ inventoryWsl.ini
    |__ playbook-blue.yml
    |__ playbook-deploy-green.yml
    |__ playbook-green.yml
    |__ rollback.yml
    |__ rollback-green.bat
    |__ Jenkinsfile
    |__ Vagrantfile

### 3 - Implementation

### 3.1 Infrastructure

First, the Vagrantfile is created, which defines and configures the two virtual machines needed for the project. This file uses the bento/ubuntu-22.04 image as a base and configures two identical VMs with minor differences in networking and provisioning:

```vagrantfile

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "blue" do |blue|
    blue.vm.hostname = "ca6-blue"
    blue.vm.network "private_network", ip: "192.168.56.10"
    blue.vm.network "forwarded_port", guest: 8080, host: 8085
    blue.vm.network "forwarded_port", guest: 8082, host: 8086
    
    blue.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "ca6-blue-vm"
    end

    blue.vm.provision "shell", inline: <<-SHELL
      sleep 20
    SHELL

    blue.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "playbook-blue.yml"
      ansible.verbose = true
      ansible.install = true
      ansible.limit = "all"
      ansible.raw_arguments = ["-f", "1"]
      ansible.inventory_path = "inventory.ini"
      ansible.extra_vars = {
        git_token: ENV['GIT_TOKEN'] || ""
      }
    end
  end

  config.vm.define "green" do |green|
    green.vm.hostname = "ca6-green"
    green.vm.network "private_network", ip: "192.168.56.11"
    green.vm.network "forwarded_port", guest: 8080, host: 8087
    green.vm.network "forwarded_port", guest: 8082, host: 8088
    
    green.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "ca6-green-vm"
    end

    green.vm.provision "shell", inline: <<-SHELL
      sleep 20
    SHELL

    green.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "playbook-green.yml"
      ansible.verbose = true
      ansible.install = true
      ansible.limit = "green"
      ansible.raw_arguments = ["-f", "1"]
      ansible.inventory_path = "inventory.ini"
      ansible.extra_vars = {
        git_token: ENV['GIT_TOKEN'] || ""
      }
    end
  end
end
```
Each VM is provisioned through a playbook, in which the blue VM is already configured with the application deployment. For this purpose, two playbooks were created (one for each VM).

The playbooks playbook-blue.yml and playbook-green.yml are Both playbooks (playbook-blue.yml and playbook-green.yml) begin by updating the apt cache and installing OpenJDK 17, among other dependencies. Next, the complete directory structure is created with the appropriate permissions for the vagrant user. (The playbook-green.yml ends here).

Since the application needed to be deployed on the blue VM, the systemd service is created, which allows the application to be managed as a system service. This service is configured to start automatically after the network is available and run the application JAR.

```yml
- name: Set global variables
  hosts: all
  gather_facts: no
  tasks:
    - name: Set facts for all hosts
      set_fact:
        app_user: vagrant
        app_dir: /home/vagrant/app
        h2_data_dir: /home/vagrant/h2-data
        git_repo: "https://github.com/RafaeLuisPrf/cogsi2526-1221322-1201623-1151352.git"
        app_path: "PLS/CA2/Part2"

- name: Provision Blue VM
  hosts: all
  become: yes
  tasks:
    - name: Wait for dpkg lock
      shell: |
        while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
          echo "Waiting for dpkg lock..."
          sleep 5
        done
      become: yes

    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install JDK and JRE
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - openjdk-17-jdk
        - openjdk-17-jre

    - name: Install Netcat
      apt:
        name: netcat
        state: present

    - name: Create H2 data directory
      file:
        path: "{{ h2_data_dir }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0775'

    - name: Create application directory
      file:
        path: "{{ app_dir }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'

- name: Deploy application to Blue VM
  hosts: blue
  become: yes
  vars:
    service_name: spring-app-blue
  tasks:
    - name: Clone repository with authentication
      git:
        repo: "{{ 'https://' + git_token + '@github.com/RafaeLuisPrf/cogsi2526-1221322-1201623-1151352.git' if git_token is defined and git_token else git_repo }}"
        dest: "{{ app_dir }}/repo"
        version: main
        force: yes
      become_user: "{{ app_user }}"

    - name: Check if gradlew exists
      stat:
        path: "{{ app_dir }}/repo/{{ app_path }}/gradlew"
      register: gradlew_stat

    - name: Make gradlew executable
      file:
        path: "{{ app_dir }}/repo/{{ app_path }}/gradlew"
        mode: '0755'
      when: gradlew_stat.stat.exists

    - name: Build application with Gradle
      command: ./gradlew build --no-daemon
      args:
        chdir: "{{ app_dir }}/repo/{{ app_path }}"
      become_user: "{{ app_user }}"
      environment:
        JAVA_HOME: /usr/lib/jvm/java-17-openjdk-amd64

    - name: Configure H2 database for persistence
      lineinfile:
        path: "{{ app_dir }}/repo/{{ app_path }}/src/main/resources/application.properties"
        regexp: '^spring.datasource.url='
        line: "spring.datasource.url=jdbc:h2:file:{{ h2_data_dir }}/jpadb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
        create: yes

    - name: Stop Blue service if running
      systemd:
        name: "{{ service_name }}"
        state: stopped
      ignore_errors: yes

    - name: Find JAR file
      find:
        paths: "{{ app_dir }}/repo/{{ app_path }}/build/libs/"
        patterns: "*.jar"
        excludes: "*-plain.jar"
      register: jar_files

    - name: Create systemd service for Blue
      copy:
        dest: "/etc/systemd/system/{{ service_name }}.service"
        content: |
          [Unit]
          Description=Spring Boot Application Blue
          After=network.target

          [Service]
          Type=simple
          User={{ app_user }}
          WorkingDirectory={{ app_dir }}/repo/{{ app_path }}
          ExecStart=/usr/bin/java -jar {{ jar_files.files[0].path }}
          Restart=on-failure
          RestartSec=10

          [Install]
          WantedBy=multi-user.target
        mode: '0644'

    - name: Reload systemd daemon
      systemd:
        daemon_reload: yes

    - name: Enable and restart Blue service
      systemd:
        name: "{{ service_name }}"
        enabled: yes
        state: restarted

```
After this, the application is running on the blue VM and the green VM already has the dependencies and directories configured (deployment will be done later via Jenkins).

### 3.2 Jenkins Pipeline

The following Jenkinsfile was created:

```java
pipeline {
    agent any
    
    environment {
        GIT_TOKEN = credentials('git-token-credential-id')
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        STABLE_TAG = "stable-v${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code from repository...'
                git branch: 'CA6_P1',
                    url: 'https://github.com/RafaeLuisPrf/cogsi2526-1221322-1201623-1151352.git',
                    credentialsId: 'git-token-credential-id'
            }
        }
        
        stage('Assemble') {
            steps {
                echo 'Compiling code and producing artifacts...'
                dir('PLS/CA2/Part2') {
                    script {
                        if (isUnix()) {
                            sh 'chmod +x gradlew'
                            sh './gradlew clean assemble --no-daemon'
                        } else {
                            bat 'gradlew.bat clean assemble --no-daemon'
                        }
                    }
                }
            }
        }
        
        stage('Test') {
        steps {
            echo 'Running unit tests...'
            dir('PLS/CA2/Part2') {
                script {
                    if (isUnix()) {
                        sh './gradlew test --no-daemon'
                    } else {
                        bat 'gradlew.bat test --no-daemon'
                    }
                }
            }
        }
        post {
            always {
                junit 'PLS/CA2/Part2/build/test-results/test/*.xml'
                publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'PLS/CA2/Part2/build/reports/tests/test',
                    reportFiles: 'index.html',
                    reportName: 'Test Report'
                    ])
                }
            }
        }
        
        stage('Archive') {
            steps {
                echo 'Archiving artifacts...'
                archiveArtifacts artifacts: 'PLS/CA2/Part2/build/libs/*.jar', 
                                 fingerprint: true,
                                 allowEmptyArchive: false
            }
        }
        
        stage('Tag Stable Build') {
            steps {
                echo "Tagging stable build as ${STABLE_TAG}..."
                script {
                    if (isUnix()) {
                        sh """
                            git config user.name "SantiagoAzevedo"
                            git config user.email "1201623@isep.ipp.pt"
                            git tag -a ${STABLE_TAG} -m "Stable build ${env.BUILD_NUMBER} - All tests passed"
                            git push https://${GIT_TOKEN}@github.com/RafaeLuisPrf/cogsi2526-1221322-1201623-1151352.git ${STABLE_TAG}
                        """
                    } else {
                        bat """
                            git config user.name "SantiagoAzevedo"
                            git config user.email "1201623@isep.ipp.pt"
                            git tag -a ${STABLE_TAG} -m "Stable build ${env.BUILD_NUMBER} - All tests passed"
                            git push https://%GIT_TOKEN%@github.com/RafaeLuisPrf/cogsi2526-1221322-1201623-1151352.git ${STABLE_TAG}
                        """
                    }
                }
                echo "Build tagged successfully as ${STABLE_TAG}"
            }
        }
        
        stage('Deploy to Production?') {
            steps {
                echo 'Requesting manual approval for production deployment...'
                script {
                    def userInput = input(
                        id: 'deployApproval',
                        message: 'Deploy to Production (Green VM)?',
                        parameters: [
                            choice(
                                name: 'DEPLOY_DECISION',
                                choices: ['No', 'Yes'],
                                description: 'Do you approve the deployment to the Green VM?'
                            )
                        ]
                    )
                    
                    if (userInput == 'No') {
                        error('Deployment to production was rejected by user.')
                    }
                    
                    echo "Deployment approved! Proceeding to Green VM..."
                }
            }
        }

        stage('WSL Check') {
            steps {
                bat "wsl -l -v"
            }
        }

        stage('Prepare SSH Keys') {
            steps {
                echo 'Copying Vagrant SSH keys to WSL...'
                script {
                    bat """
                        wsl bash -c "mkdir -p ~/.ssh && cp /mnt/c/Users/Admin/Documents/COGSI/cogsi2526-1221322-1201623-1151352/PLS/CA6/Part1/.vagrant/machines/green/virtualbox/private_key ~/.ssh/green_key && chmod 600 ~/.ssh/green_key"
                    """
                }
            }
        }
        
        stage('Deploy') {
            steps{
                script {
                    bat """
                        wsl bash -c "ansible-playbook -i /mnt/c/Users/Admin/Documents/COGSI/cogsi2526-1221322-1201623-1151352/PLS/CA6/Part1/inventoryWsl.ini /mnt/c/Users/Admin/Documents/COGSI/cogsi2526-1221322-1201623-1151352/PLS/CA6/Part1/playbook-deploy-green.yml --limit green --extra-vars 'git_token=${env.GIT_TOKEN}'"
                    """
                }
            }
        }
```

The Jenkinsfile defines the complete CI/CD pipeline with the steps listed in the statement. First, **Checkout** clones the latest code from the branch. **Assemble** navigates to CA2/Part2 and runs ./gradlew clean assemble to compile the application and produce the JAR. Next, the **Test** stage runs ./gradlew test and publishes the results to Jenkins using the JUnit plugin. The **Archive** stage archives the JAR artifacts produced with active fingerprinting. The **Deploy to Production?** stage asks the user if they want to deploy to the green VM. If so, **Deploy** executes ansible-playbook -i inventory.ini deploy-green.yml, invoking playbook-deploy-green.yml.

As can be seen, the Deploy stage has a particularity. Since Ansible is not compatible with Windows, it is necessary to find a solution to run the deploy playbook on the VM. Thus, the solution found is to use WSL to connect to the VM and run Ansible. For this to happen, it is necessary to create an inventory file that specifies the Green host (192.168.56.11) with the private SSH key and allows automatic connections without manual intervention:

```java
[blue]
192.168.56.10 ansible_connection=ssh ansible_user=vagrant ansible_ssh_private_key_file=~/.ssh/blue_key

[green]
192.168.56.11 ansible_connection=ssh ansible_user=vagrant ansible_ssh_private_key_file=~/.ssh/green_key

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30'
app_user=vagrant

```

<span style="color:red">Important note:</span> for security and dynamic reasons, both when running Vagrant and Jenkins, the authentication token for the GitHub account is obtained through $env:git_token = “TOKEN_HERE” in cmd.



### 3.3 Tagging and Versioning

Tags are only placed in the repository when tests are validated. The tag name follows the build number, for example, if the build that worked was 10, the tag will be stable-v10:

```java
stage('Tag Stable Build') {
            steps {
                echo "Tagging stable build as ${STABLE_TAG}..."
                script {
                    if (isUnix()) {
                        sh """
                            git config user.name "SantiagoAzevedo"
                            git config user.email "1201623@isep.ipp.pt"
                            git tag -a ${STABLE_TAG} -m "Stable build ${env.BUILD_NUMBER} - All tests passed"
                            git push https://${GIT_TOKEN}@github.com/RafaeLuisPrf/cogsi2526-1221322-1201623-1151352.git ${STABLE_TAG}
                        """
                    } else {
                        bat """
                            git config user.name "SantiagoAzevedo"
                            git config user.email "1201623@isep.ipp.pt"
                            git tag -a ${STABLE_TAG} -m "Stable build ${env.BUILD_NUMBER} - All tests passed"
                            git push https://%GIT_TOKEN%@github.com/RafaeLuisPrf/cogsi2526-1221322-1201623-1151352.git ${STABLE_TAG}
                        """
                    }
                }
                echo "Build tagged successfully as ${STABLE_TAG}"
            }
        }
```

### 3.4 Post-Actions

```java
        stage('Deployment Verification') {
            steps {
                echo 'Verifying deployment with health checks...'
                script {
                    def healthCheckPassed = false
                    def maxRetries = 10
                    def retryCount = 0
                    
                    while (!healthCheckPassed && retryCount < maxRetries) {
                        retryCount++
                        echo "Health check attempt ${retryCount}/${maxRetries}..."
                        
                        try {
                            bat """
                                wsl bash -c "curl -f -s http://192.168.56.11:8080 > /dev/null && echo 'Health check passed' || exit 1"
                            """
                            healthCheckPassed = true
                            echo 'Application is responding correctly on Green VM!'
                        } catch (Exception e) {
                            if (retryCount < maxRetries) {
                                echo "Health check failed, retrying in 10 seconds..."
                                sleep(10)
                            } else {
                                error('Deployment verification failed: Application is not responding after ${maxRetries} attempts')
                            }
                        }
                    }
                }
            }
        }

    }
    
    post {
        success {
            script {
                def message = """
                PIPELINE EXECUTION SUCCESSFUL
                Job Name    : ${env.JOB_NAME}
                Build Number: #${env.BUILD_NUMBER}
                Status      : SUCCESS
                Tag         : ${STABLE_TAG}
                Duration    : ${currentBuild.durationString}
                
                Deployment  : Application successfully deployed to Green VM
                Health Check: PASSED - Application is responding correctly
                """
                echo message
            }
        }
        failure {
            script {
                def message = """
                PIPELINE EXECUTION FAILED
                Job Name    : ${env.JOB_NAME}
                Build Number: #${env.BUILD_NUMBER}
                Status      : FAILURE
                Duration    : ${currentBuild.durationString}
                
                Failed Stage: Check the logs above for details
                Action      : Review the error logs and fix the issues
                """
                echo message
            }
        }
        unstable {
            script {
                def message = """
                PIPELINE EXECUTION UNSTABLE
                Job Name    : ${env.JOB_NAME}
                Build Number: #${env.BUILD_NUMBER}
                Status      : UNSTABLE
                Duration    : ${currentBuild.durationString}
                
                Warning     : Build completed with warnings or test failures
                """
                echo message
            }
        }
        always {
            echo 'Pipeline execution completed.'
        }
    }
```
After deployment, the connection to the application on the green VM is tested 10 times (to allow connection even if the service takes a while to start) and, finally, a success, failure, or unstable message appears, taking into account the entire pipeline process.

![alt text](Images/Part1/pipeline_success.png)

### 3.5 Rollback green VM

The rollback playbook allows the application to be stopped if it is running on the green VM, accesses the stable version of the application (confirmed by the tag created from the pipeline), restarts the application, and finally tests the connection:

```yml
- name: Rollback Green VM to previous stable version
  hosts: green
  become: yes
  vars:
    service_name: spring-app-green
    stable_tag: "stable-v5" 
    jenkins_url: "http://192.168.56.1:10000"
    jenkins_user: "SantiagoAzevedo"
    jenkins_token: "--- IGNORE ---" 
    artifact_path: "/job/CA6-Part1/lastSuccessfulBuild/artifact/PLS/CA2/Part2/build/libs/Part2-0.0.1-SNAPSHOT.jar"
    dest_jar: "/home/vagrant/app/repo/PLS/CA2/Part2/build/libs/Part2-0.0.1-SNAPSHOT.jar"

  tasks:
    - name: Stop Green service
      systemd:
        name: "{{ service_name }}"
        state: stopped
      ignore_errors: yes

    - name: Download stable artifact from Jenkins
      get_url:
        url: "{{ jenkins_url }}{{ artifact_path }}"
        dest: "{{ dest_jar }}"
        url_username: "{{ jenkins_user }}"
        url_password: "{{ jenkins_token }}"
        force_basic_auth: yes
        force: yes
        mode: '0644'

    - name: Restart Green service
      systemd:
        name: "{{ service_name }}"
        state: restarted
        enabled: yes

    - name: Health check - wait for app to respond
      uri:
        url: "http://localhost:8080/employees"
        status_code: 200
        timeout: 10
        return_content: no
      register: health
      retries: 10
      delay: 10
      until: health.status == 200
```
The same problem arises with Ansible's incompatibility with Windows, so the rollback-green.bat script was created to run the playbook inside the VM through WSL:

```bat
@echo off

set JENKINS_USER=SantiagoAzevedo
set JENKINS_TOKEN=""
set STABLE_TAG=stable-v5

set INVENTORY=/mnt/c/Users/Admin/Documents/COGSI/cogsi2526-1221322-1201623-1151352/PLS/CA6/Part1/inventoryWsl.ini
set PLAYBOOK=/mnt/c/Users/Admin/Documents/COGSI/cogsi2526-1221322-1201623-1151352/PLS/CA6/Part1/rollback.yml

wsl bash -c "ansible-playbook -i %INVENTORY% %PLAYBOOK% --limit green --extra-vars 'jenkins_user=%JENKINS_USER% jenkins_token=%JENKINS_TOKEN% stable_tag=%STABLE_TAG%'"
```

## Part 2

### 1 - Analysis / Requirements

### 2 - Design of the solution
        
### 3 - Implementation


## Alternative solution

### 1.1 - Requirements

### 1.2 - Analysis

### 1.3 - Requirements of part 1 and 2

### 2 - Design of the solution

### 3 - Implementation


