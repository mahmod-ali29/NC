#These Files are used to build the Ghost Image
```diff
-Dockerfile
-docker-entrypoint.sh
-ssh_setup.sh
-sshd_config
```
#Infrastructure Scripts
```diff
-main.sh
-azuredeploy.json
```

#How to deploy the infrastructure

```diff
- open CloudShell in bash mode
- cd clouddrive
- git clone https://github.com/mahmod-ali29/NC.git
- cd NC/AzureCLI
- bash main.sh
```

#To delete all posts once use the following file
```diff
serverless-script.sh
```
#How to run the serverless script
```diff
- cd .. // go back to NC folder
- bash serverless-script.sh
```
