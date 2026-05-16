# Before & After: Single EC2 → Multi-Environment

## 📊 What Changed

### BEFORE: Single EC2 Deployment

```
┌─────────────┐      git push       ┌──────────────────┐
│  Developer  ├────────────────────▶│  GitHub Repo     │
└─────────────┘                     └────────┬─────────┘
                                             │
                                             ▼
                                    ┌──────────────────┐
                                    │  CI Workflow     │
                                    │  - Build images  │
                                    │  - Push to Hub   │
                                    └────────┬─────────┘
                                             │
                                             ▼
                                    ┌──────────────────┐
                                    │  CD Workflow     │
                                    │  - SSH to EC2    │
                                    │  - docker compose│
                                    │    pull & up -d  │
                                    └────────┬─────────┘
                                             │
                                             ▼
                                    ┌──────────────────┐
                                    │ EC2: Live App    │
                                    │ (both stage & prod
                                    │  ran on same box)
                                    └──────────────────┘
```

**Issues with this approach:**
- ❌ No separation between stage and production
- ❌ Can't test changes safely before production
- ❌ Rolling back production affects staging
- ❌ Single point of failure
- ❌ No environment-specific configurations

---

### AFTER: Multi-Environment (Stage + Prod)

```
┌─────────────┐      git push       ┌──────────────────┐
│  Developer  ├────────────────────▶│  GitHub Repo     │
└─────────────┘                     └────────┬─────────┘
                                             │
                                             ▼
                                    ┌──────────────────┐
                                    │  CI Workflow     │
                                    │  - Build images  │
                                    │  - Tag :latest   │
                                    │    & :sha        │
                                    │  - Push to Hub   │
                                    └────────┬─────────┘
                                             │
                        ┌────────────────────┼────────────────────┐
                        │                    │                    │
                        ▼                    ▼                    ▼
                ┌──────────────────┐  ┌──────────────────┐
                │ CD-Stage         │  │ CD-Prod          │
                │ Workflow         │  │ Workflow         │
                │ SSH to Docker    │  │ SSH to EC2       │
                │ Ubuntu, deploy   │  │ Instance, deploy │
                │ with .env.stage  │  │ with .env.prod   │
                │ & docker-compose │  │ & docker-compose │
                │ .stage.yml       │  │ .prod.yml        │
                └────────┬─────────┘  └────────┬─────────┘
                         │                    │
                         ▼                    ▼
                ┌──────────────────┐  ┌──────────────────┐
                │ Docker Ubuntu    │  │ EC2              │
                │ Stage App        │  │ Production App   │
                │ mysql_data_stage │  │ mysql_data_prod  │
                │ :stage           │  │ :prod            │
                └──────────────────┘  └──────────────────┘
```

**Benefits of this approach:**
- ✅ Separate stage and production environments
- ✅ Test thoroughly on stage before prod release
- ✅ Easy rollback of just one environment
- ✅ Different configs for each environment
- ✅ Different database for each environment
- ✅ Scalable — can add more environments later (dev, qa, etc.)

---

## 🔄 Configuration Comparison

### Old Setup (.env file on EC2)

```bash
# Single .env file on EC2 server
MYSQL_ROOT_PASSWORD=single_password
DB_NAME=skillpulse
DB_USER=skillpulse
DB_PASSWORD=single_password
PORT=8080
```

**Problem:** Same database for both stage and production testing.

---

### New Setup (Environment-specific .env files)

**Stage (`.env.stage` on Docker Ubuntu):**
```bash
MYSQL_ROOT_PASSWORD=stage_password
DB_NAME=skillpulse_stage
DB_USER=skillpulse_stage
DB_PASSWORD=stage_password
ENVIRONMENT=stage
```

**Prod (`.env.prod` on EC2):**
```bash
MYSQL_ROOT_PASSWORD=prod_secure_password
DB_NAME=skillpulse_prod
DB_USER=skillpulse_prod
DB_PASSWORD=prod_secure_password
ENVIRONMENT=prod
```

**Benefit:** Completely separate databases and configurations.

---

## 📁 Docker Compose Files

### Old Setup (single docker-compose.yml)

```yaml
services:
  db:
    image: mysql:8.4
    volumes:
      - mysql_data:/var/lib/mysql  # Single volume
  backend:
    image: trainwithshubham/skillpulse-backend:latest
  frontend:
    image: trainwithshubham/skillpulse-frontend:latest
    ports:
      - "80:80"
volumes:
  mysql_data:  # Shared for all environments
```

**Problem:** Only one compose file, same config for everything.

---

### New Setup (environment-specific compose files)

**`docker-compose.stage.yml`:**
```yaml
services:
  db:
    restart: unless-stopped  # Lighter
    volumes:
      - mysql_data_stage:/var/lib/mysql  # Stage-specific
    logging:
      options:
        max-size: "10m"  # Smaller logs
        max-file: "3"
volumes:
  mysql_data_stage:
```

**`docker-compose.prod.yml`:**
```yaml
services:
  db:
    restart: always  # Heavier protection
    volumes:
      - mysql_data_prod:/var/lib/mysql  # Prod-specific
    logging:
      options:
        max-size: "50m"  # Larger logs
        max-file: "5"
volumes:
  mysql_data_prod:
```

**Benefits:**
- Different restart policies (stage: lenient, prod: strict)
- Different logging levels (stage: minimal, prod: comprehensive)
- Separate database volumes (no cross-contamination)

---

## 🔄 Deployment Workflows

### Old Setup (single `cd.yml` workflow)

```yaml
name: CD
on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          script: |
            cd ~/github-actions-kubernetes-masterclass
            git pull origin main
            docker compose pull
            docker compose up -d
```

**Problem:** Hardcoded to EC2 only.

---

### New Setup (separate `cd-stage.yml` and `cd-prod.yml`)

**`cd-stage.yml`:**
```yaml
name: CD-Stage
on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]

jobs:
  deploy-stage:
    runs-on: ubuntu-latest
    steps:
      - uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.STAGE_HOST }}
          username: ${{ secrets.STAGE_USER }}
          key: ${{ secrets.STAGE_SSH_KEY }}
          script: |
            cd ~/github-actions-kubernetes-masterclass
            git pull origin main
            docker compose -f docker-compose.stage.yml pull
            docker compose -f docker-compose.stage.yml up -d
```

**`cd-prod.yml`:**
```yaml
name: CD-Prod
on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]

jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    steps:
      - uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key: ${{ secrets.PROD_SSH_KEY }}
          script: |
            cd ~/github-actions-kubernetes-masterclass
            git pull origin main
            docker compose -f docker-compose.prod.yml pull
            docker compose -f docker-compose.prod.yml up -d
```

**Benefits:**
- Both deploy in parallel after CI succeeds
- Different SSH keys and hosts for each environment
- Can disable one without affecting the other
- Clear separation of concerns

---

## 🛠️ Local Commands

### Old Setup

```bash
# Limited control
docker compose up -d

# No easy way to manage stage vs prod
docker compose logs
```

### New Setup

```bash
# Clear commands for each environment
make setup-stage          # Initialize stage
make setup-prod           # Initialize prod

make deploy-stage         # Deploy to stage
make deploy-prod          # Deploy to prod

make logs-stage           # View stage logs
make logs-prod            # View prod logs

make down-stage           # Stop stage
make down-prod            # Stop prod

make help                 # See all options
```

**Benefit:** No confusion about which environment you're managing.

---

## 📊 File Structure Changes

### Old Structure

```
├── .env                          # Single file, unclear scope
├── docker-compose.yml            # One compose file
├── .github/workflows/
│   ├── ci.yml
│   └── cd.yml                    # Hardcoded to EC2
└── Makefile                      # Limited to k8s
```

### New Structure

```
├── .env.stage.example            # Template for stage
├── .env.prod.example             # Template for prod
├── .env.stage                    # Stage (gitignored)
├── .env.prod                     # Prod (gitignored)
├── docker-compose.yml            # Shared base (optional)
├── docker-compose.stage.yml      # Stage-specific
├── docker-compose.prod.yml       # Prod-specific
├── .github/workflows/
│   ├── ci.yml                    # Build (shared)
│   ├── cd-stage.yml              # Deploy to stage
│   └── cd-prod.yml               # Deploy to prod
├── Makefile                      # Multi-env commands
├── MULTI_ENV_SETUP.md            # Setup guide
├── GITHUB_ACTIONS_CONFIG.md      # CI/CD secrets
├── docs/
│   ├── DEPLOYMENT.md             # Full deployment guide
│   ├── skillpulse-cicd-guide.pdf # CI/CD details
│   └── skillpulse-kubernetes-guide.pdf
└── k8s/                          # Still available for local dev
```

---

## 🎯 Key Takeaways

| Aspect | Old | New |
|--------|-----|-----|
| **Environments** | 1 (EC2 only) | 2 (Docker Ubuntu + EC2) |
| **Env Files** | 1 shared | 2 separate |
| **Compose Files** | 1 | 2 |
| **Workflows** | 1 CD | 2 CD (parallel) |
| **Databases** | 1 shared | 2 separate |
| **Config Management** | Limited | Full separation |
| **Testing Before Prod** | Risky | Safe |
| **Rollback Options** | All-or-nothing | Per-environment |
| **Scalability** | Limited | Extensible |

---

## 🚀 Migration Path

1. ✅ Create new environment files (`.env.stage.example`, `.env.prod.example`)
2. ✅ Create environment-specific compose files
3. ✅ Create separate CD workflows
4. ✅ Update Makefile with multi-env commands
5. ✅ Update GitHub Actions secrets
6. ✅ Test stage deployment on Docker Ubuntu
7. ✅ Test prod deployment on EC2
8. ✅ Remove or archive old `cd.yml` workflow
9. ✅ Update documentation
10. ✅ Train team on new workflow

You're at step 5! ✅

---

## 📚 Next Steps

1. Read [`MULTI_ENV_SETUP.md`](MULTI_ENV_SETUP.md) for complete setup
2. Read [`GITHUB_ACTIONS_CONFIG.md`](GITHUB_ACTIONS_CONFIG.md) for secret configuration
3. Run `make setup-stage` and `make setup-prod`
4. Configure GitHub Actions secrets
5. Test locally: `make deploy-stage`
6. Push to main to test full CI/CD pipeline
