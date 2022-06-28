# Terraforming Apache2 in AWS
With this project you'll be able to create an ec2 instance deployed on a custom VPC on a custom subnet, and assign it a public IP address to be able to connect via ssh and handle web traffic.
This instance is configured to be created in the `us-east-1` region.

<div align="center">
  <img width="95%" src="https://i.imgur.com/eB0jKzj.jpg" align="center" alt="AWS Console" />
</div>

## Before doing anything 

[Modify](https://github.com/nicoacu/Terraforming-Apache2-in-AWS/blob/main/main.tf#L19) the `access_key` and `secret_key` with the ones from your AWS account. Be aware to not publish these credentials in a public repository, instead use secrets to securely authenticate to your cloud provider (AWS Secrets Manager, Azure KeyVault, Hashicorp Vault, etc.).

Make sure to replace the [key_name](https://github.com/nicoacu/Terraforming-Apache2-in-AWS/blob/main/main.tf#L156) parameter with the name of your key pair to be able to connect via ssh. 





- Use `terraform init` to initialize terraform and install all the necessary plugins (in this case for the AWS provider).
- Use `terraform apply` to set up the terraform configuration (main.tf).
- Use `terraform destroy` to remove it.
