# GitHub Actions Configuration Checklist

## 🔐 Secrets to Add

Go to: **Settings > Secrets and variables > Actions > New repository secret**

### Stage Environment Secrets

| Name | Value | Example |
|------|-------|---------|
| `STAGE_HOST` | Docker Ubuntu IP or hostname | `192.168.1.100` or `stage.example.com` |
| `STAGE_USER` | SSH username | `ubuntu` or `root` |
| `STAGE_SSH_KEY` | Private SSH key (full content) | `-----BEGIN RSA PRIVATE KEY-----` ... |

### Prod Environment Secrets

| Name | Value | Example |
|------|-------|---------|
| `PROD_HOST` | EC2 instance IP or hostname | `54.123.45.67` or `prod.example.com` |
| `PROD_USER` | EC2 SSH username | `ubuntu` (for Ubuntu AMI) or `ec2-user` (for Amazon Linux) |
| `PROD_SSH_KEY` | EC2 private key (full content) | `-----BEGIN RSA PRIVATE KEY-----` ... |

---

## 📝 Variables to Add

Go to: **Settings > Secrets and variables > Actions > New repository variable**

| Name | Value | Purpose |
|------|-------|---------|
| `DEPLOY_ENABLED` | `true` | Enable automatic deployments on push |

---

## 🔑 How to Get SSH Keys

### For Docker Ubuntu

On your Docker Ubuntu machine:

```bash
# Generate a key pair (if you don't have one)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github-actions -N ""

# Get the private key (entire content including BEGIN/END lines)
cat ~/.ssh/github-actions

# Add public key to authorized_keys
cat ~/.ssh/github-actions.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Verify SSH works from another machine
ssh -i ~/.ssh/github-actions <user>@<stage-host>
```

Copy the **entire private key** output (between `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`) into GitHub as `STAGE_SSH_KEY`.

### For EC2 Instance

Your EC2 instance should already have a key pair (created when you launched it).

```bash
# On your laptop, find the .pem file (e.g., from AWS console)
cat ~/path/to/your-key.pem

# Or generate a new key pair
# In AWS Console: EC2 > Key Pairs > Create Key Pair
# Download the .pem file
```

Copy the **entire content** of your `.pem` file into GitHub as `PROD_SSH_KEY`.

---

## ✅ Verify Secrets Are Set

1. Go to: **Settings > Secrets and variables > Actions**
2. You should see:
   - ✅ `STAGE_HOST`
   - ✅ `STAGE_USER`
   - ✅ `STAGE_SSH_KEY`
   - ✅ `PROD_HOST`
   - ✅ `PROD_USER`
   - ✅ `PROD_SSH_KEY`
   - ✅ `DEPLOY_ENABLED` (variable, not secret)

---

## 🧪 Test SSH Connectivity

Before enabling auto-deployment, verify SSH works:

```bash
# Test Stage connection
ssh -i <private-key> <STAGE_USER>@<STAGE_HOST>

# Test Prod connection
ssh -i <ec2-key> <PROD_USER>@<PROD_HOST>

# Both should connect without password prompts
```

If they fail:
- Check IP address is correct
- Verify SSH key is authorized on the target machine
- Check security groups (AWS) or firewall rules allow port 22

---

## 📋 Deployment Checklist

- [ ] Created `.env.stage` from `.env.stage.example`
- [ ] Created `.env.prod` from `.env.prod.example`
- [ ] Added `STAGE_HOST` secret
- [ ] Added `STAGE_USER` secret
- [ ] Added `STAGE_SSH_KEY` secret
- [ ] Added `PROD_HOST` secret
- [ ] Added `PROD_USER` secret
- [ ] Added `PROD_SSH_KEY` secret
- [ ] Added `DEPLOY_ENABLED = true` variable
- [ ] Tested SSH to Stage machine
- [ ] Tested SSH to Prod machine
- [ ] Tested `make deploy-stage` locally
- [ ] Committed and pushed a change to main
- [ ] Verified CI workflow ran successfully
- [ ] Verified CD-Stage workflow ran successfully
- [ ] Verified CD-Prod workflow ran successfully

---

## 🚀 When Ready

Once all secrets are configured and SSH is verified:

```bash
# Push a change to trigger the pipeline
git add .
git commit -m "Enable multi-environment CI/CD deployment"
git push origin main

# Watch in GitHub Actions: Settings > Actions
# Should see: CI → CD-Stage → CD-Prod (in parallel)
```

---

## ⚠️ Security Notes

- **Never commit `.env.stage` or `.env.prod`** — they contain passwords
- **SSH keys should have restricted permissions**: `chmod 600 ~/.ssh/github-actions`
- **Rotate SSH keys periodically**
- **Use strong database passwords** — not `password123`
- **GitHub Secrets are encrypted** — safe to paste SSH keys
- **Consider IP whitelisting** on your machines to allow only GitHub Actions runner IPs

---

## 🆘 Troubleshooting

### "Permission denied (publickey)" in CD workflow

- Verify public key is in `~/.ssh/authorized_keys` on target machine
- Check `~/.ssh/authorized_keys` permissions: `chmod 600`
- Ensure SSH key is the full content (include BEGIN/END lines)

### "Host key verification failed"

GitHub Actions can't verify the SSH host key. Add to deploy script:

```bash
mkdir -p ~/.ssh
echo 'StrictHostKeyChecking=no' >> ~/.ssh/config
```

(Already handled in our `appleboy/ssh-action` — no changes needed)

### Variables/Secrets show as "unknown" in workflow

- Wait a few moments for GitHub to refresh
- Try refreshing the page
- Verify you're in the correct repo

### Workflows don't trigger

- Check `DEPLOY_ENABLED = true`
- Verify you're pushing to `main` branch
- Check CI workflow completes successfully before CD starts

---

## 📚 More Info

- Full guide: [`MULTI_ENV_SETUP.md`](MULTI_ENV_SETUP.md)
- Deployment details: [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)
- GitHub Actions docs: https://docs.github.com/en/actions
