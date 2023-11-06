#!/bin/bash

echo "Tearing down Helm"
helm uninstall --namespace jenkins jenkins --wait
helm uninstall --namespace kmeyer-inadev kmeyer-inadev --wait

echo "Tearing down Terraform"
pushd terraform/eks
terraform destroy -auto-approve -var-file=tfvars/inadev.tfvars -var "jenkins_agent_image=teardown" -var "jenkins_agent_tag=teardown" 
popd

echo "Tearing down ECR"
pushd terraform/ecr
terraform destroy -auto-approve -var "force_delete_ecr_repositories=true"
popd
