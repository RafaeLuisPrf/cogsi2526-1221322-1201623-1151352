@echo off

set JENKINS_USER=SantiagoAzevedo
set JENKINS_TOKEN=""
set STABLE_TAG=stable-v5

set INVENTORY=/mnt/c/Users/Admin/Documents/COGSI/cogsi2526-1221322-1201623-1151352/PLS/CA6/Part1/inventoryWsl.ini
set PLAYBOOK=/mnt/c/Users/Admin/Documents/COGSI/cogsi2526-1221322-1201623-1151352/PLS/CA6/Part1/rollback.yml

wsl bash -c "ansible-playbook -i %INVENTORY% %PLAYBOOK% --limit green --extra-vars 'jenkins_user=%JENKINS_USER% jenkins_token=%JENKINS_TOKEN% stable_tag=%STABLE_TAG%'"