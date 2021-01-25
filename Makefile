NAMESPACE = connaisseur
IMAGE = $(IMAGE_NAME):$(TAG)
IMAGE_NAME = securesystemsengineering/connaisseur
TAG = v1.2.0
HELM_HOOK_IMAGE := securesystemsengineering/connaisseur:helm-hook-v1.0

.PHONY: all docker certs install unistall upgrade annihilate

all: docker install

docker:
	docker build -f docker/Dockerfile -t $(IMAGE) .
	docker build -f docker/Dockerfile.hook -t $(HELM_HOOK_IMAGE) .

certs:
	bash helm/certs/gen_certs.sh

install: certs
	kubectl create ns $(NAMESPACE) || true
	kubectl config set-context --current --namespace $(NAMESPACE)
	#
	#=============================================
	#
	# The installation may last up to 5 minutes.
	#
	#=============================================
	#
	helm install connaisseur helm --wait --debug

uninstall:
	kubectl config set-context --current --namespace $(NAMESPACE)
	helm uninstall connaisseur
	kubectl delete ns $(NAMESPACE) --timeout=120s

upgrade:
	kubectl config set-context --current --namespace $(NAMESPACE)
	helm upgrade connaisseur helm --wait --debug

annihilate:
	kubectl delete all,mutatingwebhookconfigurations,clusterroles,clusterrolebindings,configmaps,imagepolicies -lapp.kubernetes.io/instance=connaisseur
