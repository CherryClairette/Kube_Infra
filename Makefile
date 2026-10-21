PROFILE ?= kubequest2

.PHONY: connect

# Usage: make connect INSTANCE=i-0123456789abcdef0
connect:
ifndef INSTANCE
	$(error INSTANCE is not set. Usage: make connect INSTANCE=i-xxx)
endif
	aws sso login --profile $(PROFILE)
	aws --profile $(PROFILE) ec2 describe-instances \
		--query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`]|[0].Value]' \
		--output table
	aws --profile $(PROFILE) ssm start-session --target $(INSTANCE)