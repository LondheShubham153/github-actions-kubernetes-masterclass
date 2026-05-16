# 🚀 Quick Start: Multi-Environment Setup

## 5-Minute Setup

### Step 1: Create Environment Files

```bash
cd ~/Projects/github-actions-kubernetes-masterclass
make setup-stage
make setup-prod
```

Output:
```
✅ Created .env.stage from example
📝 Edit .env.stage with your Docker Ubuntu credentials
✅ Created .env.prod from example
📝 Edit .env.prod with your EC2 credentials
```

### Step 2: Edit `.env.stage`

```bash
nano .env.stage  # or use your editor
```

Replace with your **Docker Ubuntu** details:
```bash
DOCKERHUB_USERNAME=your_username
DOCKERHUB_TOKEN=your_token
MYSQL_ROOT_PASSWORD=stage_password
DB_NAME=skillpulse_stage
DB_USER=skillpulse_stage
DB_PASSWORD=stage_password
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

### Step 3: Edit `.env.prod`

```bash
nano .env.prod
```

Replace with your **EC2** details:
```bash
DOCKERHUB_USERNAME=your_username
DOCKERHUB_TOKEN=your_token
MYSQL_ROOT_PASSWORD=prod_password_secure
DB_NAME=skillpulse_prod
DB_USER=skillpulse_prod
DB_PASSWORD=prod_password_secure
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

### Step 4: Test Locally

Deploy to your Docker Ubuntu machine:

```bash
make deploy-stage
```

Expected output:
```
🚀 Deploying to STAGE (Docker Ubuntu)...
✅ Stage deployment complete
NAME      IMAGE                                                   COMMAND             SERVICE   STATUS      PORTS
...
```

### Step 5: Add GitHub Secrets

Go to: **GitHub > Your Repo > Settings > Secrets and variables > Actions**

Click: **New repository secret**

Add these 6 secrets:

| Name | Value |
|------|-------|
| `STAGE_HOST` | Your Docker Ubuntu IP (e.g., `192.168.1.100`) |
| `STAGE_USER` | SSH user (e.g., `ubuntu`) |
| `STAGE_SSH_KEY` | Your SSH private key (full content) |
| `PROD_HOST` | Your EC2 IP (e.g., `54.123.45.67`) |
| `PROD_USER` | EC2 user (usually `ubuntu`) |
| `PROD_SSH_KEY` | Your EC2 private key (full content) |

### Step 6: Enable Auto-Deployment

Go to: **GitHub > Your Repo > Settings > Variables**

Click: **New repository variable**

Add:
- Name: `DEPLOY_ENABLED`
- Value: `true`

### Step 7: Test the Pipeline

```bash
git add .
git commit -m "Enable multi-environment CI/CD"
git push origin main
```

Go to: **GitHub > Your Repo > Actions**

Watch the pipeline:
1. **CI** — Builds images (5 mins)
2. **CD-Stage** — Deploys to Docker Ubuntu (2 mins)
3. **CD-Prod** — Deploys to EC2 (2 mins)

---

## 🎯 Key Commands

```bash
# Setup (run first time only)
make setup-stage
make setup-prod

# Deploy locally
make deploy-stage
make deploy-prod

# View logs
make logs-stage
make logs-prod

# Stop services
make down-stage
make down-prod

# See all commands
make help
```

---

## 📁 What Was Created

| File | Purpose |
|------|---------|
| `.env.stage.example` | Template for stage environment |
| `.env.prod.example` | Template for prod environment |
| `docker-compose.stage.yml` | Stage deployment config |
| `docker-compose.prod.yml` | Prod deployment config |
| `.github/workflows/cd-stage.yml` | Auto-deploy to Docker Ubuntu |
| `.github/workflows/cd-prod.yml` | Auto-deploy to EC2 |
| `Makefile` | Updated with multi-env commands |
| `MULTI_ENV_SETUP.md` | Full setup guide |
| `GITHUB_ACTIONS_CONFIG.md` | CI/CD configuration details |
| `BEFORE_AND_AFTER.md` | What changed and why |
| `docs/DEPLOYMENT.md` | Complete deployment documentation |

---

## ✅ Verify Everything Works

### 1. Local Stage Deployment

```bash
make deploy-stage
docker compose -f docker-compose.stage.yml ps
```

Should show: `backend`, `frontend`, `db` all running.

### 2. Check GitHub Actions Secrets

**Settings > Secrets and variables > Actions**

Should show 6 secrets (dots = masked):
- ✅ STAGE_HOST
- ✅ STAGE_USER
- ✅ STAGE_SSH_KEY
- ✅ PROD_HOST
- ✅ PROD_USER
- ✅ PROD_SSH_KEY

### 3. Push a Change

```bash
git add .
git commit -m "test"
git push origin main
```

Check **Actions** tab — should see CI, CD-Stage, and CD-Prod workflows running.

---

## ⚠️ Don't Commit These Files

These contain secrets — keep them local only:
```bash
.env.stage        # Don't commit
.env.prod         # Don't commit
```

They're already in `.gitignore` (created automatically).

---

## 🐛 Troubleshooting

| Problem | Fix |
|---------|-----|
| `Permission denied` in CD workflow | Check SSH key is in `authorized_keys` on target machine |
| `Connection refused` | Verify IP address is correct in GitHub secrets |
| `.env.stage` not found | Run `make setup-stage` |
| Workflows don't run | Check `DEPLOY_ENABLED = true` in Variables |
| Images not pulling | Verify Docker Hub credentials in `.env.stage/.env.prod` |

---

## 📚 Documentation Files

1. **[`MULTI_ENV_SETUP.md`](MULTI_ENV_SETUP.md)** — Complete setup guide (start here)
2. **[`GITHUB_ACTIONS_CONFIG.md`](GITHUB_ACTIONS_CONFIG.md)** — Secrets and configuration
3. **[`BEFORE_AND_AFTER.md`](BEFORE_AND_AFTER.md)** — What changed and why
4. **[`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)** — Full deployment details

---

## 🎉 You're All Set!

Your SkillPulse app now deploys to both:
- 🐳 **Stage**: Docker Ubuntu (for testing)
- ☁️ **Prod**: EC2 (for production)

Each push to `main`:
1. Builds new images
2. Deploys to Stage automatically
3. Deploys to Prod automatically
4. Takes ~9 minutes total

Happy deploying! 🚀
