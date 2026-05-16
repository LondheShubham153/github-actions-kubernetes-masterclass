# SkillPulse Deployment - Multi-Environment Support
# Usage:
#   make deploy-stage    - Deploy to Docker Ubuntu (staging)
#   make deploy-prod     - Deploy to EC2 (production)
#   make logs-stage      - View stage logs
#   make logs-prod       - View prod logs

.PHONY: deploy-stage deploy-prod logs-stage logs-prod setup-stage setup-prod down-stage down-prod help k8s-up k8s-down k8s-logs k8s-build k8s-load k8s-apply

help:
	@echo "Available commands:"
	@echo ""
	@echo "  Setup (run these first):"
	@echo "    make setup-stage          Create .env.stage from example"
	@echo "    make setup-prod           Create .env.prod from example"
	@echo ""
	@echo "  Deployment:"
	@echo "    make deploy-stage         Deploy to Stage (Docker Ubuntu)"
	@echo "    make deploy-prod          Deploy to Prod (EC2)"
	@echo ""
	@echo "  Management:"
	@echo "    make logs-stage           Tail stage logs"
	@echo "    make logs-prod            Tail prod logs"
	@echo "    make down-stage           Stop stage containers"
	@echo "    make down-prod            Stop prod containers"
	@echo ""
	@echo "  Kubernetes (local dev):"
	@echo "    make k8s-up               Create local kind cluster"
	@echo "    make k8s-down             Delete local kind cluster"
	@echo "    make k8s-logs             View k8s logs"

# ============================================
# SETUP
# ============================================

setup-stage:
	@if [ ! -f .env.stage ]; then \
		cp .env.stage.example .env.stage; \
		echo "✅ Created .env.stage from example"; \
		echo "📝 Edit .env.stage with your Docker Ubuntu credentials"; \
	else \
		echo "⚠️  .env.stage already exists"; \
	fi

setup-prod:
	@if [ ! -f .env.prod ]; then \
		cp .env.prod.example .env.prod; \
		echo "✅ Created .env.prod from example"; \
		echo "📝 Edit .env.prod with your EC2 credentials"; \
	else \
		echo "⚠️  .env.prod already exists"; \
	fi

# ============================================
# STAGE DEPLOYMENT (Docker Ubuntu)
# ============================================

deploy-stage: check-stage-env
	@echo "🚀 Deploying to STAGE (Docker Ubuntu)..."
	docker compose -f docker-compose.stage.yml pull
	docker compose -f docker-compose.stage.yml up -d
	@echo "✅ Stage deployment complete"
	@docker compose -f docker-compose.stage.yml ps

logs-stage:
	docker compose -f docker-compose.stage.yml logs -f

down-stage:
	@echo "🛑 Stopping STAGE containers..."
	docker compose -f docker-compose.stage.yml down
	@echo "✅ Stage stopped"

# ============================================
# PROD DEPLOYMENT (EC2)
# ============================================

deploy-prod: check-prod-env
	@echo "🚀 Deploying to PROD (EC2)..."
	docker compose -f docker-compose.prod.yml pull
	docker compose -f docker-compose.prod.yml up -d
	@echo "✅ Prod deployment complete"
	@docker compose -f docker-compose.prod.yml ps

logs-prod:
	docker compose -f docker-compose.prod.yml logs -f

down-prod:
	@echo "🛑 Stopping PROD containers..."
	docker compose -f docker-compose.prod.yml down
	@echo "✅ Prod stopped"

# ============================================
# KUBERNETES (Local Development)
# ============================================

CLUSTER  ?= skillpulse
NAMESPACE ?= skillpulse
BACKEND_IMAGE  ?= trainwithshubham/skillpulse-backend:latest
FRONTEND_IMAGE ?= trainwithshubham/skillpulse-frontend:latest

k8s-up: k8s-build
	kind create cluster --config k8s/kind-config.yaml --name $(CLUSTER)
	$(MAKE) k8s-load
	$(MAKE) k8s-apply
	@echo ""
	@echo "  SkillPulse is live at http://localhost:8888"
	@echo ""

k8s-build:
	docker build -t $(BACKEND_IMAGE)  ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend

k8s-load:
	kind load docker-image $(BACKEND_IMAGE)  --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE) --name $(CLUSTER)

k8s-apply:
	kubectl apply -f k8s/00-namespace.yaml \
	              -f k8s/10-mysql.yaml \
	              -f k8s/20-backend.yaml \
	              -f k8s/30-frontend.yaml
	kubectl rollout status statefulset/mysql    -n $(NAMESPACE) --timeout=180s
	kubectl rollout status deployment/backend   -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend  -n $(NAMESPACE) --timeout=60s

k8s-down:
	kind delete cluster --name $(CLUSTER)

k8s-logs:
	kubectl logs -n $(NAMESPACE) -l 'app in (mysql,backend,frontend)' --all-containers --tail=50 -f --max-log-requests=10

# ============================================
# HELPERS
# ============================================

check-stage-env:
	@if [ ! -f .env.stage ]; then \
		echo "❌ .env.stage not found"; \
		echo "Run: make setup-stage"; \
		exit 1; \
	fi

check-prod-env:
	@if [ ! -f .env.prod ]; then \
		echo "❌ .env.prod not found"; \
		echo "Run: make setup-prod"; \
		exit 1; \
	fi
