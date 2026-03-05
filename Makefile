.PHONY: init plan apply destroy kubeconfig talosconfig new-app validate fmt

TF_DIR := terraform

init:
	cd $(TF_DIR) && terraform init

plan:
	cd $(TF_DIR) && terraform plan

apply:
	cd $(TF_DIR) && terraform apply

destroy:
	cd $(TF_DIR) && terraform destroy

validate:
	cd $(TF_DIR) && terraform validate

fmt:
	cd $(TF_DIR) && terraform fmt -recursive

kubeconfig:
	cd $(TF_DIR) && terraform output -raw kubeconfig > ../kubeconfig
	@echo "Saved to ./kubeconfig"

talosconfig:
	cd $(TF_DIR) && terraform output -raw talosconfig > ../talosconfig
	@echo "Saved to ./talosconfig"

nodes:
	kubectl --kubeconfig=kubeconfig get nodes -o wide

pods:
	kubectl --kubeconfig=kubeconfig get pods -A

# Create a new application from the skeleton
# Usage: make new-app NAME=my-service
new-app:
ifndef NAME
	$(error Usage: make new-app NAME=my-service)
endif
	@if [ -d "apps/$(NAME)" ]; then echo "Error: apps/$(NAME) already exists"; exit 1; fi
	cp -r apps/myapp "apps/$(NAME)"
	LC_ALL=C find "apps/$(NAME)" -type f -exec sed -i.bak 's/myapp/$(NAME)/g' {} + && find "apps/$(NAME)" -name '*.bak' -delete
	@echo "Created apps/$(NAME) -- edit values.yaml and Dockerfile to customize"
