# Multi-Environment Setup Summary

## ✅ What Changed

Your SkillPulse deployment now supports **two environments**: Stage (Docker Ubuntu) and Prod (EC2).

### 📁 New Files Created

1. **`.env.stage.example`** — Template for Stage environment variables
2. **`.env.prod.example`** — Template for Prod environment variables
3. **`docker-compose.stage.yml`** — Stage deployment configuration
4. **`docker-compose.prod.yml`** — Prod deployment configuration
5. **`.github/workflows/cd-stage.yml`** — Automated Stage deployment workflow
6. **`.github/workflows/cd-prod.yml`** — Automated Prod deployment workflow
7. **`docs/DEPLOYMENT.md`** — Complete deployment guide

### 🔄 Modified Files

1. **`Makefile`** — Added multi-environment targets:
   - `make setup-stage` — Initialize Stage environment
   - `make setup-prod` — Initialize Prod environment
   - `make deploy-stage` — Deploy to Docker Ubuntu
   - `make deploy-prod` — Deploy to EC2
   - `make logs-stage` / `make logs-prod` — View logs
   - `make down-stage` / `make down-prod` — Stop services
   - Original `make k8s-up/down/logs` for local Kubernetes still available

---

## 🚀 Setup Steps

### Step 1: Create Environment Files

```bash
cd ~/github-actions-kubernetes-masterclass
make setup-stage
make setup-prod
```

This creates `.env.stage` and `.env.prod` from the examples.

### Step 2: Configure Stage Environment

Edit `.env.stage` with your Docker Ubuntu credentials:

```bash
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=your_dockerhub_password_or_token
MYSQL_ROOT_PASSWORD=stage_root_password
DB_NAME=skillpulse_stage
DB_USER=skillpulse_stage
DB_PASSWORD=stage_db_password
```

### Step 3: Configure Prod Environment

Edit `.env.prod` with your EC2 credentials:

```bash
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=your_dockerhub_password_or_token
MYSQL_ROOT_PASSWORD=prod_secure_root_password
DB_NAME=skillpulse_prod
DB_USER=skillpulse_prod
DB_PASSWORD=prod_secure_db_password
```

### Step 4: Test Locally

```bash
# Deploy to your local Docker Ubuntu first
make deploy-stage

# Check logs
make logs-stage

# Stop when done
make down-stage
```

### Step 5: Configure GitHub Actions

Add these **Secrets** in GitHub repo settings (`Settings > Secrets and variables > Actions`):

#### For Stage Deployment:
- `STAGE_HOST` = Your Docker Ubuntu IP/hostname
- `STAGE_USER` = SSH username (usually `ubuntu` or `root`)
- `STAGE_SSH_KEY` = Private SSH key (generate with `ssh-keygen`)

#### For Prod Deployment:
- `PROD_HOST` = Your EC2 instance IP
- `PROD_USER` = EC2 username (usually `ubuntu` or `ec2-user`)
- `PROD_SSH_KEY` = EC2 private key

Add these **Variables** (optional):
- `DEPLOY_ENABLED` = `true` (to enable auto-deployment)

### Step 6: Test CI/CD Pipeline

```bash
# On your laptop, push a small change to main
git add .
git commit -m "Enable multi-environment deployment"
git push origin main
```

Then monitor in GitHub Actions:
1. **CI** workflow builds and pushes images
2. **CD-Stage** workflow deploys to Docker Ubuntu
3. **CD-Prod** workflow deploys to EC2

---

## 🔑 Key Differences: Stage vs Prod

### Deployment Target
- **Stage**: Docker Ubuntu VM (local/test environment)
- **Prod**: EC2 (cloud/production)

### Configuration
- **Stage**: Uses `docker-compose.stage.yml`
- **Prod**: Uses `docker-compose.prod.yml`

### Resource Limits
- **Stage**: Lighter logging (10MB/file, 3 files)
- **Prod**: Heavier logging (50MB/file, 5 files)

### Restart Policy
- **Stage**: `unless-stopped` (container survives reboots only if explicitly started)
- **Prod**: `always` (container always restarts)

### Environment Variable
- **Stage**: `ENVIRONMENT=stage`
- **Prod**: `ENVIRONMENT=prod`

### Volume Names
- **Stage**: `mysql_data_stage`
- **Prod**: `mysql_data_prod`

---

## 🎯 Deployment Flow

```
DEVELOPER PUSHES TO MAIN
         ↓
    CI WORKFLOW (ci.yml)
    - Build backend image
    - Build frontend image
    - Tag with :latest and :sha
    - Push to Docker Hub
         ↓
    ┌──────────────────────────┐
    │                          │
    ↓                          ↓
CD-STAGE (cd-stage.yml)   CD-PROD (cd-prod.yml)
SSH to Docker Ubuntu      SSH to EC2 Instance
git pull                  git pull
compose -f                compose -f
  docker-compose.        docker-compose.
  stage.yml pull         prod.yml pull
up -d                     up -d
    │                          │
    ↓                          ↓
STAGE LIVE                 PROD LIVE
```

---

## 📊 What Gets Deployed

Both Stage and Prod deploy the same containerized app:

1. **MySQL 8.4** — Database
2. **Go Backend (Gin)** — API on port 8080
3. **Nginx Frontend** — Web UI on port 80

Each environment has:
- Separate database (stage vs prod)
- Separate Docker volumes
- Separate container names (app_backend_1, app_frontend_1, etc.)

---

## 🛠️ Common Operations

### Local Testing (Before Pushing to GitHub)

```bash
# Deploy to Stage
make deploy-stage

# View logs in real-time
make logs-stage

# Stop all containers
make down-stage
```

### After Pushing to GitHub

GitHub Actions automatically:
1. Builds images (CI)
2. Deploys to Stage (CD-Stage)
3. Deploys to Prod (CD-Prod)

Monitor progress: `GitHub > Actions > Latest run`

### Manual Deployment (if CI/CD is disabled)

```bash
# On Stage machine:
ssh user@stage-host
cd ~/github-actions-kubernetes-masterclass
git pull origin main
source .env.stage
docker compose -f docker-compose.stage.yml pull
docker compose -f docker-compose.stage.yml up -d

# On Prod machine:
ssh ubuntu@prod-host
cd ~/github-actions-kubernetes-masterclass
git pull origin main
source .env.prod
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

---

## ⚠️ Important Notes

### `.env` Files Are Local Only

- `.env.stage` and `.env.prod` are NOT committed to Git
- They contain sensitive credentials (passwords, tokens)
- Each machine must have its own copy
- Use `.env.stage.example` and `.env.prod.example` as templates

### SSH Setup Required

For CD workflows to work, each target machine needs:
1. SSH access from GitHub Actions
2. Docker and Docker Compose installed
3. The repo cloned (first deployment does this)
4. `.env.stage` or `.env.prod` file in the repo directory

### Separate Databases

- Stage and Prod have **different MySQL databases**
- Stage data doesn't affect Prod
- Use separate credentials for each

### Port Conflicts

Both compose files bind to port 80. Can't run both on the same machine:
- Stage: one Docker Ubuntu instance
- Prod: different EC2 instance

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `CI/CD workflows not running` | Check `DEPLOY_ENABLED` is `true` in GitHub Variables |
| `.env.stage` not found on target machine | SSH in and run `cp .env.stage.example .env.stage` |
| Images not pulling from Docker Hub | Verify Docker Hub credentials in `.env` files |
| Port 80 already in use | Change port mapping in docker-compose file |
| SSH connection refused | Verify STAGE_HOST/PROD_HOST and SSH keys are correct |
| Database connection failed | Check DB_HOST, DB_USER, DB_PASSWORD in `.env` |

---

## 📚 Documentation

- **[`docs/DEPLOYMENT.md`](DEPLOYMENT.md)** — Full deployment guide
- **[`docs/skillpulse-cicd-guide.pdf`](skillpulse-cicd-guide.pdf)** — GitHub Actions details
- **[`docs/skillpulse-kubernetes-guide.pdf`](skillpulse-kubernetes-guide.pdf)** — Kubernetes (local dev)

---

## ✨ Next Steps

1. ✅ Copy this repo to your workspace
2. ✅ Run `make setup-stage` and `make setup-prod`
3. ✅ Edit `.env.stage` and `.env.prod`
4. ✅ Test: `make deploy-stage` on Docker Ubuntu
5. ✅ Add GitHub Secrets for both environments
6. ✅ Set `DEPLOY_ENABLED = true` in GitHub Variables
7. ✅ Push a change to main to test the pipeline
8. ✅ Monitor in GitHub Actions

Happy deploying! 🚀
