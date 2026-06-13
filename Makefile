# ═══════════════════════════════════════════════════════════════════════════
#  Student Management System — Makefile
#  All operations are reproducible via `make <target>`
# ═══════════════════════════════════════════════════════════════════════════

# ── Configuration ─────────────────────────────────────────────────────────────
DOCKER_NAMESPACE  ?= walid369
DOCKER_IMAGE      ?= student-management
APP_PORT          ?= 8089
APP_CONTEXT       ?= /student
K8S_NAMESPACE     ?= student-management
HELM_RELEASE      ?= student-management
HELM_CHART        ?= ./helm/student-management
SONAR_HOST        ?= http://localhost:9000

# Auto-detect git commit SHA (fallback: 'dev')
GIT_SHA           := $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)
IMAGE_TAG         ?= $(GIT_SHA)

.PHONY: help build test sonar docker-build docker-push docker-run \
        k8s-namespace k8s-deploy k8s-status k8s-logs k8s-rollback \
        trivy-scan helm-lint helm-dry-run clean

# ── Default target ────────────────────────────────────────────────────────────
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo ""
	@echo "  Student Management — DevOps Makefile"
	@echo "  ────────────────────────────────────"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Variables:"
	@echo "    IMAGE_TAG=$(IMAGE_TAG)   DOCKER_NAMESPACE=$(DOCKER_NAMESPACE)"
	@echo "    K8S_NAMESPACE=$(K8S_NAMESPACE)   SONAR_HOST=$(SONAR_HOST)"
	@echo ""

# ── Maven ─────────────────────────────────────────────────────────────────────
build: ## Build the Maven project (skip tests)
	./mvnw clean package -DskipTests -B

test: ## Run all unit tests + JaCoCo coverage
	./mvnw clean verify -Dspring.profiles.active=test -B

sonar: ## Run SonarQube analysis (requires SONAR_TOKEN env var)
	@[ -n "$$SONAR_TOKEN" ] || (echo "❌ SONAR_TOKEN not set"; exit 1)
	./mvnw sonar:sonar \
		-Dsonar.host.url=$(SONAR_HOST) \
		-Dsonar.login=$$SONAR_TOKEN \
		-B

deps-check: ## Check for outdated Maven dependencies
	./mvnw versions:display-dependency-updates

# ── Docker ────────────────────────────────────────────────────────────────────
docker-build: ## Build Docker image with git SHA tag
	docker build \
		--pull \
		--build-arg IMAGE_TAG=$(IMAGE_TAG) \
		--build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
		--build-arg GIT_COMMIT=$(GIT_SHA) \
		-t $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):$(IMAGE_TAG) \
		-t $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):latest \
		.
	@echo "✅ Built: $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):$(IMAGE_TAG)"

docker-push: ## Push Docker image to Docker Hub (requires docker login)
	docker push $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):$(IMAGE_TAG)
	docker push $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):latest
	@echo "✅ Pushed: $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):$(IMAGE_TAG)"

docker-run: ## Run app locally with docker-compose
	docker-compose up -d
	@echo "✅ App running at http://localhost:$(APP_PORT)$(APP_CONTEXT)"

docker-stop: ## Stop docker-compose stack
	docker-compose down

docker-clean: ## Remove all dangling Docker images
	docker image prune -f

# ── Trivy Security ────────────────────────────────────────────────────────────
trivy-scan: ## Scan Docker image for CVEs with Trivy
	@mkdir -p target/trivy-reports
	trivy image \
		--severity HIGH,CRITICAL \
		--format table \
		$(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):$(IMAGE_TAG)
	trivy image \
		--severity HIGH,CRITICAL \
		--format json \
		--output target/trivy-reports/trivy-report.json \
		$(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):$(IMAGE_TAG)
	@echo "📄 JSON report: target/trivy-reports/trivy-report.json"

# ── Helm / Kubernetes ─────────────────────────────────────────────────────────
helm-lint: ## Lint the Helm chart
	helm lint $(HELM_CHART)

helm-dry-run: ## Dry-run Helm deployment
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(K8S_NAMESPACE) \
		--create-namespace \
		--dry-run \
		-f $(HELM_CHART)/values.yaml

k8s-namespace: ## Create Kubernetes namespace
	kubectl create namespace $(K8S_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "✅ Namespace: $(K8S_NAMESPACE)"

k8s-deploy: ## Deploy to Kubernetes via Helm (requires env vars for secrets)
	@[ -n "$$MYSQL_ROOT_PASSWORD" ] || (echo "❌ MYSQL_ROOT_PASSWORD not set"; exit 1)
	@[ -n "$$MYSQL_APP_USER" ] || (echo "❌ MYSQL_APP_USER not set"; exit 1)
	@[ -n "$$MYSQL_APP_PASSWORD" ] || (echo "❌ MYSQL_APP_PASSWORD not set"; exit 1)
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(K8S_NAMESPACE) \
		--create-namespace \
		--atomic \
		--timeout 5m \
		-f $(HELM_CHART)/values.yaml \
		-f $(HELM_CHART)/values-prod.yaml \
		--set image.tag=$(IMAGE_TAG) \
		--set mysqlSecret.rootPassword="$$MYSQL_ROOT_PASSWORD" \
		--set mysqlSecret.appUser="$$MYSQL_APP_USER" \
		--set mysqlSecret.appPassword="$$MYSQL_APP_PASSWORD" \
		--set appSecret.actuatorUser="$${ACTUATOR_USER:-admin}" \
		--set appSecret.actuatorPassword="$${ACTUATOR_PASSWORD:-changeme}" \
		--set appSecret.apiUser="$${API_USER:-api-user}" \
		--set appSecret.apiPassword="$${API_PASSWORD:-changeme}"
	kubectl rollout status deployment/$(HELM_RELEASE) -n $(K8S_NAMESPACE) --timeout=300s
	@echo "✅ Deployed $(HELM_RELEASE) to namespace $(K8S_NAMESPACE)"

k8s-status: ## Show status of all K8s resources in namespace
	@echo "\n── Pods ─────────────────────────────────"
	kubectl get pods -n $(K8S_NAMESPACE) -o wide
	@echo "\n── Services ─────────────────────────────"
	kubectl get svc -n $(K8S_NAMESPACE)
	@echo "\n── HPA ──────────────────────────────────"
	kubectl get hpa -n $(K8S_NAMESPACE)
	@echo "\n── Helm releases ────────────────────────"
	helm list -n $(K8S_NAMESPACE)

k8s-logs: ## Follow application logs in Kubernetes
	kubectl logs -n $(K8S_NAMESPACE) \
		-l app.kubernetes.io/name=$(DOCKER_IMAGE) \
		-f --tail=100

k8s-rollback: ## Rollback Helm release to previous version
	helm rollback $(HELM_RELEASE) -n $(K8S_NAMESPACE) --wait
	@echo "🔁 Rollback complete"

k8s-delete: ## Delete the Helm release (keeps namespace)
	helm uninstall $(HELM_RELEASE) -n $(K8S_NAMESPACE)

k8s-apply-raw: ## Apply raw YAML manifests (fallback, no Helm)
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/configmap.yaml
	kubectl apply -f k8s/mysql.yaml
	kubectl apply -f k8s/app-deployment.yaml
	kubectl apply -f k8s/app-service.yaml
	kubectl apply -f k8s/hpa.yaml
	kubectl apply -f k8s/networkpolicy.yaml
	@echo "✅ Raw manifests applied"

# ── Health Check ──────────────────────────────────────────────────────────────
health: ## Check application health via Minikube
	@MINIKUBE_IP=$$(minikube ip 2>/dev/null || echo localhost) ; \
	echo "🔍 Health: http://$$MINIKUBE_IP:30089$(APP_CONTEXT)/actuator/health" ; \
	curl -sf -u "$${ACTUATOR_USER:-admin}:$${ACTUATOR_PASSWORD:-changeme}" \
		"http://$$MINIKUBE_IP:30089$(APP_CONTEXT)/actuator/health" | \
		python3 -m json.tool 2>/dev/null || \
	curl -sf -u "$${ACTUATOR_USER:-admin}:$${ACTUATOR_PASSWORD:-changeme}" \
		"http://$$MINIKUBE_IP:30089$(APP_CONTEXT)/actuator/health"

# ── Cleanup ───────────────────────────────────────────────────────────────────
clean: ## Clean Maven build artifacts + Docker dangling images
	./mvnw clean -q
	docker image prune -f
	@echo "✅ Clean complete"
