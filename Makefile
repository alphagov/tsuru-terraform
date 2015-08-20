.PHONY: all prep \
	aws gce refresh-aws refresh-gce\
	check-env-var check-env-aws \
	plan-aws plan-gce start-aws start-gce

TERRAFORM_CMD = cd $(1) && \
	terraform $(2) \
	-state=${DEPLOY_ENV}.tfstate \
	-var env=${DEPLOY_ENV} \
	-var force_destroy=${DESTROY_BUCKET} \
	${ARGS} && cd ..

ifndef DESTROY_BUCKET
	DESTROY_BUCKET=false
endif

all:
	$(error Usage: make <action> DEPLOY_ENV=name [DESTROY_BUCKET=true] [ARGS=extra_args])
prep:
	touch aws/ETCD_CLUSTER_ID gce/ETCD_CLUSTER_ID

aws: check-env-var check-env-aws
	$(call TERRAFORM_CMD,aws,apply)

gce: check-env-var
	$(call TERRAFORM_CMD,gce,apply)

refresh-aws: check-env-var check-env-aws
	$(call TERRAFORM_CMD,aws,refresh)

refresh-gce: check-env-var
	$(call TERRAFORM_CMD,gce,refresh)

plan-aws: check-env-var check-env-aws
	$(call TERRAFORM_CMD,aws,plan)

plan-gce: check-env-var
	$(call TERRAFORM_CMD,gce,plan)

taint-aws: check-env-var check-env-aws
	 $(call TERRAFORM_CMD,aws,taint)

taint-gce: check-env-var
	$(call TERRAFORM_CMD,gce,taint)

destroy-aws: check-env-var check-env-aws
	$(call TERRAFORM_CMD,aws,destroy)

destroy-gce: check-env-var
	$(call TERRAFORM_CMD,gce,destroy)

check-env-aws: check-env-var
ifndef AWS_SECRET_ACCESS_KEY
	$(error Environment variable AWS_SECRET_ACCESS_KEY must be set)
endif
ifndef AWS_ACCESS_KEY_ID
	$(error Environment variable AWS_ACCESS_KEY_ID must be set)
endif

check-env-var:
ifndef DEPLOY_ENV
	$(error Must pass DEPLOY_ENV=<name>)
endif

start-aws: check-env-var check-env-aws
	cd aws && \
	terraform taint -state=${DEPLOY_ENV}.tfstate aws_elb.api-ext && \
	terraform taint -state=${DEPLOY_ENV}.tfstate aws_elb.api-int && \
	terraform taint -state=${DEPLOY_ENV}.tfstate aws_elb.router && \
	cd .. && \
	$(call TERRAFORM_CMD,aws,apply)

start-gce: check-env-var
	$(call TERRAFORM_CMD,gce,apply)
