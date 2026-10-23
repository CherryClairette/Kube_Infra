PROFILE ?= kubequest2

.DEFAULT_GOAL := help
.PHONY: help connect

help: ## Show this help
	@echo "Usage: make <target> [VAR=value]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables:"
	@echo "  PROFILE    AWS SSO profile (default: $(PROFILE))"
	@echo "  INSTANCE   EC2 instance ID, required by connect (e.g. i-0123456789abcdef0)"
	@echo ""

# Usage: make connect INSTANCE=i-0123456789abcdef0"
connect: ## Log in to AWS SSO, list instances, open an SSM session (needs INSTANCE=i-xxx)
ifndef INSTANCE
	$(error INSTANCE is not set. Usage: make connect INSTANCE=i-xxx)
endif
	aws sso login --profile $(PROFILE)
	aws --profile $(PROFILE) ec2 describe-instances \
		--query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`]|[0].Value]' \
		--output table
	aws --profile $(PROFILE) ssm start-session --target $(INSTANCE)