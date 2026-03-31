# Deployment Script - Sync to Customer Repository

This script automates copying the web build to the customer's production repository.

## 📋 Setup (One-Time)

### 1. Customer Creates Repository

Customer should have:
- GitHub account created
- Repository: `mk-dashboard-production`
- GitHub Pages enabled (main branch → /docs/web)

### 2. Add Customer Repo as Remote

```bash
cd D:\mk\parser\mobile

# Build web version
flutter build web --release

# Copy to docs/web
xcopy /E /I /Y build\web ..\..\docs\web
```

### 3. Commit and Push to YOUR GitHub

```bash
cd D:\mk
git add docs/web
git commit -m "Deploy web build to production"
git push origin main
```

---

## 🚀 Deployment Options

### **Option A: Manual Copy (Simple)**

**For you (developer):**

```bash
# 1. Build
cd D:\mk\parser\mobile
flutter build web --release

# 2. Copy to customer folder
xcopy /E /I /Y build\web D:\customer-deploy\mk-dashboard-production\docs\web

# 3. Customer commits and pushes
cd D:\customer-deploy\mk-dashboard-production
git add docs/web
git commit -m "Update dashboard"
git push
```

**Customer's folder:** `D:\customer-deploy\mk-dashboard-production\`

---

### **Option B: Automated Script (Recommended)**

Create a deployment batch file:

**File:** `D:\mk\deploy-to-customer.bat`

```batch
@echo off
echo ========================================
echo MK Dashboard - Deploy to Customer
echo ========================================
echo.

REM Build web version
echo Building Flutter web app...
cd D:\mk\parser\mobile
call flutter build web --release
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Copying to docs/web...
xcopy /E /I /Y build\web ..\..\docs\web

echo.
echo Committing to YOUR GitHub...
cd D:\mk
git add docs/web
git commit -m "Deploy web build %DATE%"
git push origin main

echo.
echo ========================================
echo ✅ Deployment to YOUR GitHub complete!
echo ========================================
echo.
echo Next step:
echo Customer needs to pull from their repo and push to their GitHub
echo.
pause
```

---

### **Option C: Git Submodule (Advanced)**

**Setup:**

```bash
# In customer's repo
cd D:\customer-deploy\mk-dashboard-production

# Add your repo as submodule
git submodule add https://github.com/bounthongv/mk-restaurants-dashboard.git source

# Configure to track docs/web from submodule
git commit -m "Add development repo as submodule"
git push
```

**Deploy:**

```bash
# Update submodule to latest
cd D:\customer-deploy\mk-dashboard-production
git submodule update --remote

# Copy web build
xcopy /E /I /Y source\docs\web docs\web

# Commit and push
git add docs/web
git commit -m "Update from development repo"
git push
```

---

## 📝 Recommended Workflow

### **Weekly Deployment**

1. **You develop** during the week on your GitHub
2. **Friday afternoon:** Build and test
3. **Copy to customer repo**
4. **Customer reviews** (optional)
5. **Customer pushes** to their GitHub
6. **GitHub Pages auto-deploys**

### **Emergency Updates**

Same process, just faster:
1. Fix bug
2. Build
3. Deploy
4. Notify customer

---

## 🔄 Customer's Role

**Customer needs to:**

1. **Create GitHub account** (one-time)
2. **Create repository** (one-time)
3. **Enable GitHub Pages** (one-time)
4. **Pull updates** from your repo (when you notify)
5. **Push to their GitHub** (triggers auto-deploy)

**OR** give you access to their repo and you handle everything!

---

## 💡 Pro Tips

### 1. Give Developer Access

Customer can add you as collaborator to their repo:

**Customer does:**
- Settings → Collaborators → Add your GitHub username

**You can:**
- Push directly to their repo
- No need for customer to do anything

### 2. Automated Deployment

Set up GitHub Actions in customer's repo to auto-deploy when you push:

**File:** `.github/workflows/deploy.yml` (in customer's repo)

```yaml
name: Auto-Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs/web
```

Now deployments are **fully automatic**!

---

## ✅ Deployment Checklist

Before deploying:

- [ ] Web build successful (`flutter build web --release`)
- [ ] Tested locally (open `build/web/index.html`)
- [ ] Version number updated
- [ ] CHANGELOG updated (if needed)
- [ ] Customer notified (if manual deployment)

After deploying:

- [ ] GitHub Pages shows success (green checkmark)
- [ ] Dashboard URL loads correctly
- [ ] Data displays properly
- [ ] Customer confirms working

---

## 🆘 Troubleshooting

### Build Fails

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release
```

### GitHub Pages Not Updating

1. Wait 2 minutes (deployment takes time)
2. Hard refresh browser (Ctrl + F5)
3. Check Actions tab for errors
4. Verify `docs/web/index.html` exists in repo

### Customer Can't Access Repo

- Check they're logged in with correct GitHub account
- Verify they accepted collaborator invitation
- Try incognito/private browser mode

---

**Deployment is ready!** 🚀

Choose the option that works best for your workflow!
