# Multi-Environment Deployment Guide

This guide explains how to set up SkillPulse for **two environments**: Stage (Docker Ubuntu) and Prod (EC2).

---

## 📋 Overview

```
┌─────────────┐     git push        ┌──────────────────┐
│  Developer  ├────────────────────▶│  GitHub Repo     │
└─────────────┘                     └────────┬─────────┘
                                             │
                          ┌──────────────────┼──────────────────┐
                          │                  │                  │
                          ▼                  ▼                  ▼
                    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
                    │  CI Workflow │  │ CD-Stage     │  │ CD-Prod      │
                    │ - Build      │  │ Workflow     │  │ Workflow     │
                    │ - Push to    │  │ - Deploy to  │  │ - Deploy to  │
                    │   Docker Hub │  │   Docker     │  │   EC2        │
                    │              │  │   Ubuntu     │  │ (Production) │
                    └──────────────┘  └──────────────┘  └──────────────┘
                                             │                  │
                                             ▼                  ▼
                                    ┌──────────────┐  ┌──────────────┐
                                    │ Stage App    │  │ Prod App     │
                                    │ Docker       │  │ EC2 Instance │
                                    │ Compose      │  │ Docker       │
                                    │ Ubuntu       │  │ Compose      │
                                    └──────────────┘  └──────────────┘
```

---

## 🔧 Directory Structure

```
├── .env.stage.example          # Template for Stage environment
├── .env.prod.example           # Template for Prod environment
├── docker-compose.yml          # Shared configuration (if any)
├── docker-compose.stage.yml    # Stage-specific (Docker Ubuntu)
├── docker-compose.prod.yml     # Prod-specific (EC2)
├── .github/
│   └── workflows/
│       ├── ci.yml             # Build & push images (shared)
│       ├── cd-stage.yml       # Deploy to Docker Ubuntu
│       └── cd-prod.yml        # Deploy to EC2
└── docs/
    └── DEPLOYMENT.md          # This file
```

---

## 🚀 Quick Start

### 1️⃣ Create Environment Files

```bash
# Copy examples to actual env files
make setup-stage
make setup-prod
```

This creates `.env.stage` and `.env.prod` from the examples.

### 2️⃣ Edit Environment Files

**`.env.stage`** — Docker Ubuntu settings:
```bash
DOCKERHUB_USERNAME=your_username
DOCKERHUB_TOKEN=your_token
MYSQL_ROOT_PASSWORD=stage_root_pass
DB_NAME=skillpulse_stage
DB_USER=skillpulse_stage
DB_PASSWORD=stage_db_pass
```

**`.env.prod`** — EC2 settings:
```bash
DOCKERHUB_USERNAME=your_username
DOCKERHUB_TOKEN=your_token
MYSQL_ROOT_PASSWORD=prod_secure_pass
DB_NAME=skillpulse_prod
DB_USER=skillpulse_prod
DB_PASSWORD=prod_secure_pass
```

### 3️⃣ Deploy Locally (for testing)

```bash
# Deploy to local Docker Ubuntu
make deploy-stage

# View logs
make logs-stage

# Stop containers
make down-stage
```

---

## 🔐 GitHub Actions Configuration

### Secrets Required

For **Stage** deployment, add these GitHub Secrets:
- `STAGE_HOST` — Docker Ubuntu IP/hostname
- `STAGE_USER` — SSH username for Docker Ubuntu
- `STAGE_SSH_KEY` — Private SSH key

For **Prod** deployment, add these GitHub Secrets:
- `PROD_HOST` — EC2 instance IP/hostname
- `PROD_USER` — EC2 SSH username (usually `ubuntu`)
- `PROD_SSH_KEY` — EC2 private key
- `DOCKERHUB_USERNAME` — Docker Hub account
- `DOCKERHUB_TOKEN` — Docker Hub token/password

### Variables (Optional)

- `DEPLOY_ENABLED` — Set to `true` to enable deployments (default: `false`)

---

## 📊 Stage vs Prod Differences

| Aspect | Stage | Prod |
|--------|-------|------|
| **Host** | Docker Ubuntu VM | EC2 Instance |
| **Compose File** | `docker-compose.stage.yml` | `docker-compose.prod.yml` |
| **Restart Policy** | `unless-stopped` | `always` |
| **Logging** | 10MB per file, 3 files max | 50MB per file, 5 files max |
| **Environment** | `ENVIRONMENT=stage` | `ENVIRONMENT=prod` |
| **Volume Names** | `mysql_data_stage` | `mysql_data_prod` |
| **Port** | 80 (exposed) | 80 (exposed) |

---

## 🎯 Deployment Workflows

### Automatic (CI/CD)

```
1. Developer pushes to main
2. CI workflow (ci.yml) runs:
   - Builds images
   - Tags with :latest and :sha
   - Pushes to Docker Hub
3. CD-Stage workflow (cd-stage.yml) runs:
   - SSHes to Docker Ubuntu
   - Pulls latest images
   - Runs: docker compose -f docker-compose.stage.yml up -d
4. CD-Prod workflow (cd-prod.yml) runs:
   - SSHes to EC2
   - Pulls latest images
   - Runs: docker compose -f docker-compose.prod.yml up -d
```

### Manual (Local)

```bash
# Deploy Stage
make deploy-stage

# Deploy Prod
make deploy-prod
```

---

## 🛠️ Common Tasks

### View Logs

```bash
# Stage logs
make logs-stage

# Prod logs
make logs-prod
```

### Restart Services

```bash
# Down and up
make down-stage
make deploy-stage
```

### SSH into Instance

```bash
# Docker Ubuntu
ssh -i <private-key> <user>@<stage-host>
cd ~/github-actions-kubernetes-masterclass
docker compose -f docker-compose.stage.yml ps

# EC2
ssh -i <ec2-key> ubuntu@<ec2-instance>
cd ~/github-actions-kubernetes-masterclass
docker compose -f docker-compose.prod.yml ps
```

### Access MySQL

```bash
# Stage
docker compose -f docker-compose.stage.yml exec db mysql -uskillpulse_stage -pstage_db_pass skillpulse_stage

# Prod
docker compose -f docker-compose.prod.yml exec db mysql -uskillpulse_prod -pprod_secure_pass skillpulse_prod
```

---

## 🔍 Troubleshooting

### CI/CD Workflows Not Running

1. Check `DEPLOY_ENABLED` variable is set to `true` in GitHub settings
2. Verify CI workflow runs successfully first
3. Check CD workflow has proper secrets configured

### Deployment Fails with "Missing .env"

On the target machine:
```bash
cd ~/github-actions-kubernetes-masterclass
cp .env.stage.example .env.stage  # for Stage
cp .env.prod.example .env.prod    # for Prod
# Edit with actual credentials
```

### Images Not Pulling

```bash
# Check Docker Hub credentials
docker login -u <DOCKERHUB_USERNAME> -p <DOCKERHUB_TOKEN>

# Manually pull
docker pull <DOCKERHUB_USERNAME>/skillpulse-backend:latest
docker pull <DOCKERHUB_USERNAME>/skillpulse-frontend:latest
```

### Port Already in Use

Stage/Prod both expose port 80. Can't run both on same machine.

```bash
# Option 1: Run on different machines
# Option 2: Use different ports in docker-compose file
```

---

## 📚 Kubernetes (Local Development)

For local development with Kubernetes:

```bash
# Create kind cluster
make k8s-up

# View logs
make k8s-logs

# Delete cluster
make k8s-down
```

---

## 📝 Next Steps

1. ✅ Run `make setup-stage` and `make setup-prod`
2. ✅ Edit `.env.stage` and `.env.prod` with your credentials
3. ✅ Test locally: `make deploy-stage`
4. ✅ Add GitHub Secrets for Stage and Prod
5. ✅ Commit and push to trigger CI/CD
6. ✅ Monitor deployments in GitHub Actions

---

## 🎓 Learning Resources

- [`docs/skillpulse-cicd-guide.pdf`](skillpulse-cicd-guide.pdf) — GitHub Actions & CI/CD
- [`docs/skillpulse-kubernetes-guide.pdf`](skillpulse-kubernetes-guide.pdf) — Kubernetes & local dev
