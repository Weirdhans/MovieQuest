# Beta Deployment Guide - MovieQuest

## 🚀 Makkelijkste Optie: Preview Deployments (Aanbevolen)

Vercel maakt **automatisch** een preview URL voor elke branch:

### Stappen:

```bash
# 1. Maak een beta branch
git checkout -b beta

# 2. Commit je Christmas feature
git add .
git commit -m "feat: add Christmas movies filter"

# 3. Push naar GitHub
git push -u origin beta
```

**✨ Klaar!** Vercel deployed automatisch naar:
- URL: `movie-matcher-flutter-git-beta-[jouw-username].vercel.app`
- Updates automatisch bij elke push naar `beta` branch
- Blijft live totdat je de branch verwijdert

### Gebruik:

- **Production** (main): `moviequest.vercel.app` (stabiele versie)
- **Beta** (beta branch): `movie-matcher-flutter-git-beta-[username].vercel.app` (test nieuwe features)

---

## 🌐 Optie 2: Custom Domain voor Beta

### Via Vercel Dashboard:

1. **Login** op [vercel.com/dashboard](https://vercel.com/dashboard)
2. Ga naar je **MovieQuest project**
3. Klik op **Settings** → **Domains**
4. Voeg toe: `beta-moviequest.vercel.app` (of eigen domain: `beta.jouw-domain.nl`)
5. Koppel aan **beta branch**

### Resultaat:
- **Production**: `moviequest.vercel.app` → `main` branch
- **Beta**: `beta-moviequest.vercel.app` → `beta` branch

### Met eigen domain (optioneel):

Als je een eigen domain hebt (bijv. `moviequest.nl`):

1. Voeg subdomain toe in Vercel: `beta.moviequest.nl`
2. Koppel aan `beta` branch
3. Voeg DNS record toe bij je DNS provider:
   ```
   Type: CNAME
   Name: beta
   Value: cname.vercel-dns.com
   TTL: 3600
   ```

---

## 🔧 Optie 3: Separaat Vercel Project (Advanced)

Voor volledige scheiding tussen prod en beta:

### Stappen:

1. **In Vercel Dashboard**:
   - Klik "Add New" → "Project"
   - Selecteer dezelfde GitHub repo
   - Project naam: `moviequest-beta`
   - Build settings: gebruik `vercel.beta.json`

2. **Git configuratie**:
   - Production branch: `main`
   - Beta project branch: `beta`

3. **Environment variabelen**:
   - Kopieer alle env vars van production
   - Optioneel: gebruik aparte Supabase project voor beta testing

### Workflow:

```bash
# Test nieuwe features in beta
git checkout beta
git merge main  # Sync met production
# ... maak wijzigingen ...
git push origin beta  # Deploy naar beta

# Na testen: merge naar production
git checkout main
git merge beta
git push origin main  # Deploy naar production
```

---

## 📋 Deployment Checklist

### Voor Beta Deploy:

- [ ] Database migratie uitgevoerd op Supabase
- [ ] Environment variabelen correct ingesteld in Vercel
- [ ] Code getest lokaal (`flutter run -d chrome`)
- [ ] Beta branch aangemaakt en gepushed
- [ ] Vercel deployment succesvol (check dashboard)

### Testing op Beta:

- [ ] Christmas toggle verschijnt in Step 2
- [ ] Toggle styling werkt (gradient, glow effect in nov/dec)
- [ ] Sessie aanmaken met Christmas mode
- [ ] Alleen kerstfilms verschijnen in swipe screen
- [ ] Summary toont Christmas mode
- [ ] Backward compatibility: oude sessies werken nog

### Voor Production Deploy:

- [ ] Beta volledig getest door gebruikers
- [ ] Geen kritieke bugs gevonden
- [ ] Performance check (loading times, API calls)
- [ ] Merge `beta` → `main`
- [ ] Push naar `main` branch

---

## 🔍 Monitoring

### Vercel Deployment Logs:

1. Ga naar [vercel.com/dashboard](https://vercel.com/dashboard)
2. Selecteer project
3. Ga naar **Deployments**
4. Klik op een deployment om logs te zien

### Build Errors:

Als de build faalt:
- Check Flutter version compatibility
- Verify environment variables
- Check `generate_env.js` output
- Review build logs in Vercel dashboard

### Runtime Errors:

- Open browser console (F12)
- Check Vercel Analytics (auto-enabled)
- Monitor Supabase logs for backend errors

---

## 💡 Tips

### Branch Strategy:

```
main (production)
  ↑
  └─ beta (testing nieuwe features)
       ↑
       └─ feature/christmas-mode (development)
```

### Testing Flow:

1. **Development**: Feature branch → lokaal testen
2. **Beta**: Merge naar `beta` → Vercel preview → gebruikers testen
3. **Production**: Merge naar `main` → live deployment

### Rollback (als iets mis gaat):

In Vercel Dashboard:
1. Ga naar **Deployments**
2. Vind de laatste werkende deployment
3. Klik op "..." → **Promote to Production**

Of via Git:
```bash
git revert HEAD
git push origin main
```

---

## 🎯 Quick Start Commando's

### Setup Beta Deployment:

```bash
# Optie 1: Preview Deployment (makkelijkst)
git checkout -b beta
git push -u origin beta
# Vercel deployed automatisch!

# Optie 2: Met custom domain
# Ga naar Vercel Dashboard → Settings → Domains
# Voeg toe: beta-moviequest.vercel.app (koppel aan beta branch)

# Optie 3: Separaat project
# Maak nieuw project in Vercel Dashboard
# Gebruik vercel.beta.json configuratie
```

### Update Beta:

```bash
git checkout beta
# ... maak wijzigingen ...
git add .
git commit -m "feat: update Christmas feature"
git push origin beta
# Vercel deployed automatisch!
```

### Deploy naar Production:

```bash
git checkout main
git merge beta
git push origin main
# Vercel deployed automatisch naar production!
```

---

## 📱 Share Beta URL

Deel de beta URL met testers:

```
Beta versie: https://movie-matcher-flutter-git-beta-[username].vercel.app

🎄 Test de nieuwe Christmas movies feature:
1. Maak een nieuwe sessie
2. Klik op de kerstboom knop in Step 2
3. Swipe door kerstfilms!
```

---

## 🆘 Hulp Nodig?

- **Vercel Docs**: https://vercel.com/docs
- **Vercel Support**: https://vercel.com/support
- **Flutter Web Docs**: https://docs.flutter.dev/platform-integration/web

## Vercel Preview URLs

Elke PR en branch krijgt automatisch een preview URL:
- Format: `movie-matcher-flutter-git-[branch-name]-[username].vercel.app`
- Updates bij elke push
- Geen extra configuratie nodig!
