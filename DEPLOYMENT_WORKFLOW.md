# Production Deployment Workflow

## 🎯 Branch Strategy

```
production (live site)
  ↑
main (staging/pre-production)
  ↑
beta (testing nieuwe features)
  ↑
feature/* (development)
```

## 🚀 Deployment Flow

### 1. Development → Beta Preview

```bash
# Ontwikkel nieuwe feature
git checkout -b feature/christmas-mode
# ... maak wijzigingen ...
git commit -m "feat: add feature"

# Merge naar beta voor testing
git checkout beta
git merge feature/christmas-mode
git push origin beta

# ✅ Vercel deployed automatisch naar preview URL
# 📍 URL: movie-quest-git-beta-[username].vercel.app
```

**Test grondig op beta preview!**

### 2. Beta → Main (Pre-Production)

Als beta preview goedgekeurd:

**Optie A - Via GitHub PR (Aanbevolen)**:
1. Ga naar GitHub → Pull Requests
2. Klik "New Pull Request"
3. Base: `main` ← Compare: `beta`
4. Review wijzigingen
5. Merge PR (voegt approval layer toe)

**Optie B - Via Command Line**:
```bash
git checkout main
git merge beta
git push origin main

# ✅ Vercel deployed naar staging URL (indien geconfigureerd)
```

### 3. Main → Production (Live Site)

**Met Manual Approval (Aanbevolen Setup)**:

#### Setup Vercel:
1. Vercel Dashboard → Project Settings → Git
2. **Production Branch**: `production`
3. **Preview Branches**: `main`, `beta`, alle anderen

#### Deployment:
```bash
# Na goedkeuring van main deployment:
git checkout production
git merge main --no-ff -m "chore: release v1.2.0"
git push origin production

# ✅ Vercel deployed naar production (movie-quests.vercel.app)
```

**Of via GitHub PR**:
1. Maak PR: `main` → `production`
2. Review en goedkeuren
3. Merge → Production live!

---

## ⚙️ Vercel Configuration

### Current Setup (Auto-Deploy Everything):
```json
{
  "productionBranch": "main",
  "previewBranches": ["beta", "feature/*"]
}
```

**Probleem**: Main pushed gaan direct live (geen approval)

### Recommended Setup (Manual Production):
```json
{
  "productionBranch": "production",
  "previewBranches": ["main", "beta", "feature/*"]
}
```

**Voordeel**:
- ✅ Beta = Preview testing
- ✅ Main = Pre-production staging
- ✅ Production = Live site (manual merge = approval)

---

## 🛡️ Safety Measures

### GitHub Branch Protection Rules

Configureer voor `production` branch:

1. **GitHub repo** → Settings → Branches → Add rule
2. Branch name pattern: `production`
3. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (1 minimum)
   - ✅ Require status checks to pass before merging
   - ✅ Require conversation resolution before merging
   - ✅ Include administrators (jezelf ook!)

Voor `main` branch:
- ✅ Require pull request reviews
- ✅ Require Vercel preview to succeed

---

## 📍 Deployment URLs

| Branch | Environment | URL | Purpose |
|--------|-------------|-----|---------|
| `feature/*` | Preview | `movie-quest-git-[branch]-[user].vercel.app` | Development testing |
| `beta` | Preview | `movie-quest-git-beta-[user].vercel.app` | Beta testing |
| `main` | Staging | `movie-quest-staging.vercel.app` (optioneel) | Pre-production |
| `production` | Production | `movie-quests.vercel.app` | Live site |

---

## 🔧 Quick Setup Commands

### 1. Create Production Branch

```bash
# Maak production branch vanuit huidige main
git checkout main
git pull origin main
git checkout -b production
git push -u origin production
```

### 2. Update Vercel Settings

```bash
# Via Vercel CLI (optioneel)
vercel link
vercel git connect
vercel env pull

# Of via Vercel Dashboard:
# Project Settings → Git → Production Branch → "production"
```

### 3. Setup Branch Protection (GitHub)

Ga naar: `https://github.com/Weirdhans/MovieQuest/settings/branches`

Add rule voor `production`:
- Branch name pattern: `production`
- Require pull request reviews: ON
- Number of approvals: 1

---

## 📝 Example Release Flow

### Christmas Feature Release:

```bash
# 1. Develop in beta
git checkout beta
# ... implement Christmas feature ...
git commit -m "feat: add Christmas movies filter"
git push origin beta

# 2. Test beta preview
# Open: movie-quest-git-beta-[user].vercel.app
# Test grondig!

# 3. Promote to staging (main)
# GitHub → New PR: beta → main
# Review + Merge

# 4. Test staging
# Open: main deployment preview
# Final checks!

# 5. Release to production (manual)
# GitHub → New PR: main → production
# Review + Approve + Merge
# ✅ LIVE!
```

---

## 🚨 Emergency Rollback

Als production kapot is:

### Optie 1: Vercel Dashboard
1. Vercel Dashboard → Deployments
2. Vind laatste werkende deployment
3. Klik "..." → **"Promote to Production"**

### Optie 2: Git Revert
```bash
git checkout production
git revert HEAD  # Revert laatste commit
git push origin production
# Vercel deployed automatisch rollback
```

### Optie 3: Git Reset (Nuclear Option)
```bash
git checkout production
git reset --hard [commit-hash]  # Hash van werkende versie
git push --force origin production
# ⚠️ Gebruik force push alleen in noodgevallen!
```

---

## ✅ Checklist Voor Production Deploy

Voordat je merged naar `production`:

- [ ] Feature getest op beta preview
- [ ] Feature getest op main/staging
- [ ] Geen console errors in browser
- [ ] Database migraties uitgevoerd
- [ ] Environment variables correct in Vercel
- [ ] Vercel build succesvol (groen vinkje)
- [ ] Analytics werkt (Vercel Analytics check)
- [ ] Breaking changes gedocumenteerd
- [ ] Team/stakeholders geïnformeerd

---

## 🎯 Next Steps

**Kies één van deze opties:**

### Optie 1: Simple (Huidige Setup + PR Workflow)
Blijf `main` als production branch, maar gebruik **altijd PR's** voor merge naar main.

**Setup:**
1. GitHub → Settings → Branches → Protect `main`
2. Require PR reviews voor merges
3. Workflow: `beta` → PR → `main` (jij reviewed + merged = approval)

**Commando's:**
```bash
git checkout beta
git push origin beta
# Test beta preview
# Als OK: maak PR op GitHub (beta → main)
# Review + Merge = production deploy
```

---

### Optie 2: Advanced (Aparte Production Branch)
Maak `production` branch speciaal voor live site.

**Setup:**
1. Maak `production` branch
2. Vercel: productionBranch = "production"
3. GitHub: Protect `production` + require PR

**Commando's:**
```bash
# Development
git checkout beta
git push origin beta  # Preview

# Pre-production
git checkout main
git merge beta
git push origin main  # Staging

# Production (manual)
git checkout production
git merge main  # Via PR op GitHub
git push origin production  # Live!
```

---

Welke optie prefereer je?
- **Optie 1**: Simpel, één extra stap (PR required)
- **Optie 2**: Volledig gescheiden environments, meer controle
