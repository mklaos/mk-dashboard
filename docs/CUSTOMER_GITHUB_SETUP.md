# MK Restaurants Dashboard - Customer Setup Guide

## 📋 Overview

This guide helps you set up the **production GitHub repository** for hosting the MK Restaurants Sales Dashboard.

**Dashboard URL (after setup):** `https://your-username.github.io/mk-dashboard-production/`

---

## Step 1: Create GitHub Account

### 1.1 Sign Up

1. Go to: **https://github.com/signup**
2. Enter your business email (e.g., `it@mk-laos.com`)
3. Create a password
4. Choose a username (suggested: `mk-laos-pos` or `mk-restaurants-laos`)
5. Verify your email

### 1.2 Recommended Username

Good options:
- `mk-laos-pos`
- `mk-restaurants-laos`
- `mk-dashboard-laos`

**Why?** Professional, easy to remember, company-related.

---

## Step 2: Create Repository

### 2.1 Create New Repository

1. After logging in, click the **"+"** icon (top right)
2. Select **"New repository"**
3. Fill in:
   - **Repository name:** `mk-dashboard-production`
   - **Description:** "MK Restaurants Sales Dashboard - Production Deployment"
   - **Visibility:** ✅ **Public** (required for free GitHub Pages)
   - ❌ Don't initialize with README

4. Click **"Create repository"**

### 2.2 Repository URL

After creation, your repo URL will be:
```
https://github.com/YOUR_USERNAME/mk-dashboard-production
```

---

## Step 3: Enable GitHub Pages

### 3.1 Go to Settings

1. In your new repository, click **"Settings"** tab (top menu)
2. Scroll down to **"Pages"** section (left sidebar)

### 3.2 Configure Pages

1. **Source:** Select **"Deploy from a branch"**
2. **Branch:** Select **"main"**
3. **Folder:** Select **"/docs/web"**
4. Click **"Save"**

### 3.3 Wait for Deployment

GitHub will deploy your site in **1-2 minutes**.

**Your dashboard URL will be:**
```
https://YOUR_USERNAME.github.io/mk-dashboard-production/
```

**Example:**
```
https://mk-laos-pos.github.io/mk-dashboard-production/
```

---

## Step 4: Initial Deployment (Developer Will Do This)

Your developer will:

1. Build the web version from their development repo
2. Copy files to your repository's `docs/web/` folder
3. Push to your repository
4. GitHub Pages will automatically deploy

**You'll receive:**
- ✅ Repository access invitation
- ✅ Dashboard URL
- ✅ Login credentials (if authentication is enabled)

---

## Step 5: Future Updates

### Automatic Updates

Your developer will handle all updates. When they push new code:

1. GitHub automatically rebuilds the site
2. Changes appear on the dashboard URL in **1-2 minutes**
3. No action needed from you!

### Manual Check (Optional)

To verify deployment status:

1. Go to your repository
2. Click **"Actions"** tab
3. See latest deployment status (green checkmark = success)

---

## 🔐 Access Control

### Who Can Access?

- **Dashboard:** Anyone with the URL (public by default)
- **Repository:** You control who can edit code
- **Settings:** Only repository owners

### Add Team Members

To add other staff:

1. Go to **Settings** → **Collaborators**
2. Click **"Add people"**
3. Enter their GitHub username
4. They'll receive an invitation

---

## 📱 Using the Dashboard

### Login (if enabled)

1. Open dashboard URL in browser (Chrome, Edge, Firefox)
2. Enter your email and password
3. Select brand and branch
4. View sales data!

### Features

- ✅ Real-time sales data
- ✅ Daily/weekly/monthly trends
- ✅ Multi-brand support (MK, Miyazaki, Hard Rock)
- ✅ Multi-branch support
- ✅ Bilingual (Lao + English)
- ✅ Export reports

---

## 💰 Cost

**100% FREE** with GitHub Pages free tier:

- ✅ Unlimited deployments
- ✅ Free HTTPS (secure)
- ✅ Global CDN (fast loading)
- ✅ Custom domain support (optional, can add later)

**No credit card required!**

---

## 🆘 Troubleshooting

### Dashboard Not Loading

1. Wait 2 minutes after deployment
2. Hard refresh browser (Ctrl + F5)
3. Check repository **Actions** tab for errors

### 404 Error

Make sure:
- ✅ GitHub Pages is enabled in Settings
- ✅ Branch is set to `main`
- ✅ Folder is set to `/docs/web`

### Data Not Showing

- Check internet connection
- Verify Supabase credentials are configured
- Contact your developer

---

## 📞 Support

**Developer Contact:**
- Name: [Your Name]
- Email: [Your Email]
- Phone: [Your Phone]

**For technical issues**, contact your developer.

**For GitHub issues** (can't login, repository access), contact GitHub Support: https://support.github.com

---

## ✅ Checklist

After setup, verify:

- [ ] GitHub account created
- [ ] Repository created: `mk-dashboard-production`
- [ ] GitHub Pages enabled
- [ ] Dashboard URL accessible
- [ ] Login works (if enabled)
- [ ] Data displays correctly
- [ ] Team members added (if needed)

---

**Congratulations! Your dashboard is now live!** 🎉

**Last Updated:** March 31, 2026
**Version:** 1.0
