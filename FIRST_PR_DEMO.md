# 🎉 Je Eerste Pull Request - Demo Guide

## 📍 Huidige Situatie

Je hebt nu:
- ✅ Christmas feature in `beta` branch
- ✅ Deployment documentatie
- ✅ PR template
- 📋 Branch protection (moet je nog instellen)

## 🚀 Laten we de Christmas Feature Deployen via PR!

### Stap 1: Branch Protection Instellen (5 min)

**EERST DIT DOEN** voordat je PR maakt:

1. Open: **https://github.com/Weirdhans/MovieQuest/settings/branches**
2. Klik **"Add branch protection rule"**
3. Vul in:
   - Branch name pattern: `main`
   - ✅ Enable: "Require a pull request before merging"
   - ✅ Enable: "Do not allow bypassing the above settings"
4. Klik **"Create"**

**Verificatie:**
```bash
# Test of direct pushen geblokkeerd is
git checkout main
echo "test" >> test.txt
git add test.txt
git commit -m "test"
git push origin main
# Zou MOETEN falen met: "Changes must be made through a pull request"
```

Als het faalt = ✅ Perfect! Branch protection werkt.

---

### Stap 2: Maak Je Eerste Pull Request

#### Optie A: Via GitHub Website (Makkelijkst)

1. **Ga naar GitHub PR pagina:**
   https://github.com/Weirdhans/MovieQuest/pulls

2. **Klik "New Pull Request"** (groene knop rechts)

3. **Selecteer branches:**
   - **base:** `main` (waar naar toe)
   - **compare:** `beta` (waar vandaan)

4. **Review de wijzigingen:**
   - Scroll door de "Files changed" tab
   - Check of alles er goed uitziet
   - Je ziet:
     - Christmas feature code
     - Database migration
     - Documentatie

5. **Klik "Create Pull Request"**

6. **Vul PR template in:**
   ```markdown
   ## 📝 Beschrijving

   Adds Christmas movies filter with seasonal prominence. Users can now filter movies to show only Christmas-themed films using TMDB keyword 207317 (~3,282 films).

   ## 🎯 Type Wijziging

   - [x] ✨ Nieuwe feature

   ## ✅ Checklist

   - [x] Code getest op beta preview URL
   - [x] Geen console errors in browser
   - [x] Database migraties uitgevoerd
   - [x] Documentatie bijgewerkt

   ## 🧪 Test Plan

   **Beta Preview URL:** movie-quest-git-beta-weirdhans.vercel.app

   **Test Scenarios:**
   1. Created new session with Christmas mode enabled
   2. Verified only Christmas movies appear in swipe screen
   3. Checked seasonal prominence in Nov/Dec
   4. Tested backward compatibility (old sessions still work)

   **Ready to merge?** ✅
   ```

7. **Klik "Create Pull Request"** (groene knop)

---

#### Optie B: Via Command Line (GitHub CLI)

```bash
# Zorg dat je in beta branch zit
git checkout beta

# Maak PR
gh pr create \
  --base main \
  --head beta \
  --title "feat: add Christmas movies filter with seasonal prominence" \
  --body "
## 📝 Beschrijving

Adds Christmas movies filter with seasonal prominence (~3,282 films).

## ✅ Checklist

- [x] Code getest op beta preview
- [x] Database migraties uitgevoerd
- [x] Documentatie bijgewerkt

## 🎄 Features

- Christmas mode toggle in Step 2
- TMDB keyword filtering (207317)
- Seasonal UI prominence (Nov/Dec)
- Full backward compatibility

Ready to merge! ✅
"
```

---

### Stap 3: Review Je Eigen PR

1. **Bekijk de PR pagina:**
   - Files changed: check alle wijzigingen
   - Conversation: ziet er goed uit?
   - Checks: wacht tot Vercel build groen is ✅

2. **Vercel Preview Check:**
   - Vercel zal een comment plaatsen met preview URL
   - Klik op de preview URL
   - Test de app NOGMAALS (extra check!)

3. **Optional: Leave a comment:**
   ```
   Tested on preview URL - Christmas mode works perfectly! 🎄
   - Toggle shows correct styling
   - Only Christmas movies appear
   - Summary displays correctly

   Ready to merge to production!
   ```

---

### Stap 4: Merge de PR

1. **Scroll naar beneden in PR**

2. **Kies merge strategie:**
   - **"Squash and merge"** (aanbevolen)
     - Combineert alle commits in 1
     - Schone git history
   - **"Merge pull request"**
     - Behoudt alle individuele commits
   - **"Rebase and merge"**
     - Lineaire history

3. **Klik groene "Squash and merge" knop**

4. **Confirm merge**
   - Review commit message
   - Klik "Confirm squash and merge"

5. **Delete beta branch?**
   - NEE! Klik **NIET** op "Delete branch"
   - Beta blijft bestaan voor toekomstige features

---

### Stap 5: Production is LIVE! 🎉

1. **Vercel deployed automatisch:**
   - Check: https://vercel.com/dashboard
   - Deployment status: Building... → Success ✅

2. **Test production:**
   - Open: https://movie-quests.vercel.app
   - Create new session
   - Check Christmas toggle in Step 2
   - Test de feature!

3. **Sync beta branch:**
   ```bash
   git checkout beta
   git merge main
   git push origin beta
   # Nu zijn beta en main weer in sync
   ```

---

## 🎊 Gefeliciteerd!

Je hebt zojuist:
- ✅ Je eerste Pull Request gemaakt
- ✅ Christmas feature gedeployed naar production
- ✅ Veilige deployment workflow opgezet
- ✅ Branch protection geactiveerd

---

## 🔄 Volgende Keer

Vanaf nu is het proces super simpel:

```bash
# 1. Feature in beta
git checkout beta
# ... maak wijzigingen ...
git push origin beta

# 2. Test beta preview
# Open preview URL, test grondig

# 3. Maak PR (GitHub of CLI)
gh pr create --base main --head beta --title "feat: nieuwe feature"

# 4. Review en merge
# GitHub website → merge PR

# 5. LIVE!
# Vercel deployed automatisch
```

---

## 💡 Pro Tips

**Tip 1: Draft PR's**
- Maak PR als "Draft" als je nog niet klaar bent
- Vercel build preview wel, maar kan niet mergen
- Convert to "Ready for review" wanneer klaar

**Tip 2: Auto-merge**
- Enable auto-merge als Vercel check groen is
- PR merged automatisch na succesvolle build

**Tip 3: PR Labels**
- Voeg labels toe: `feature`, `bugfix`, `hotfix`
- Makkelijk filteren later

**Tip 4: Milestones**
- Groepeer PR's per release (v1.1, v1.2, etc.)
- Overzicht van wat in elke release zit

---

## ❓ Veelgestelde Vragen

**Q: Kan ik meerdere features tegelijk in beta hebben?**
A: Ja! Werk met feature branches:
```bash
git checkout -b feature/christmas
git checkout -b feature/ratings
# Test beide apart, merge 1 voor 1 naar beta
```

**Q: Wat als Vercel build faalt?**
A: PR kan niet mergen totdat build groen is. Fix de error, push naar beta, wacht op nieuwe build.

**Q: Kan ik PR annuleren?**
A: Ja! Klik "Close pull request". Geen wijzigingen naar main.

**Q: Moet ik PR template altijd invullen?**
A: Nee, maar het helpt om dingen niet te vergeten!

---

Klaar om je eerste PR te maken? Go! 🚀
