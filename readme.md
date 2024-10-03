# Create/ Vuild
terraform init -upgrade
terraform plan -out main.tfplan
terraform apply main.tfplan
$resource_group_name=$(terraform output -raw resource_group_name)
Get-AzVm -ResourceGroupName $resource_group_name

# Destroy/ Clean Up
terraform plan -destroy -out main.destroy.tfplan
terraform apply main.destroy.tfplan

rm -f main.tfplan main.destroy.tfplan