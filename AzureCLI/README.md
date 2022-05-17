#These Files are used to build the Ghost Image
```diff
-Dockerfile
-docker-entrypoint.sh
-ssh_setup.sh
-sshd_config
```
#To Deploy the infrastructure on Azure
```diff
-main.sh
-azuredeploy.json
```

#How to run the script

```diff
- cd clouddrive
- git clone https://github.com/mahmod-ali29/NC.git
- cd NC/AzureCLI
- bash main.sh
```

#To delete all posts once
```diff
serverless-script.sh
```
#How to run the serverless script
```diff
- cd NC/AzureCLI
- bash serverless-script.sh
```
