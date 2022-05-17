#These Files are used to build the Ghost Image
```diff
-Dockerfile
-docker-entrypoint.sh
-ssh_setup.sh
-sshd_config
```
#Infrastructure Scripts
```diff
-terraform.tf
-variable.tfvars
```

#How to deploy the infrastructure

```diff
- open CloudShell in bash mode
- cd clouddrive
- git clone https://github.com/mahmod-ali29/NC.git
- cd NC/Terraform
- bash main.sh

#If any error occurs during the run. Then comment lines 8-18 of the main.sh file
```

#To delete all posts once, run the serverless script
```diff
- bash serverless-script.sh
```
