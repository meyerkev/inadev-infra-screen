#!/bin/bash

echo "Tearing down Helm"
helm uninstall --namespace jenkins jenkins --wait
helm uninstall --namespace kmeyer-inadev kmeyer-inadev --wait

# Sometimes the load balancer doesn't get deleted and you have to manually kill it
# https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#LoadBalancers
echo "Tearing down Terraform"
pushd terraform/eks
terraform destroy -auto-approve -var-file=tfvars/inadev.tfvars -var "jenkins_agent_image=teardown" -var "jenkins_agent_tag=teardown" 
popd

echo "Tearing down ECR"
pushd terraform/ecr
terraform destroy -auto-approve -var-file=teardown.tfvars
popd
