# Branch Protection Setup - Optie 1

## 🎯 Doel
Bescherm `main` branch zodat alleen via Pull Requests kan worden gemerged (= jouw approval moment)

## 📋 Stappen (5 minuten)

### 1. Open GitHub Branch Settings

Ga naar: **https://github.com/Weirdhans/MovieQuest/settings/branches**

Of:
1. GitHub.com → je MovieQuest repository
2. Klik op **Settings** (tandwiel icoon)
3. Klik op **Branches** in het linkermenu

### 2. Maak Branch Protection Rule

Klik op **"Add branch protection rule"** of **"Add rule"**

### 3. Configureer de Rule

Vul in:

**Branch name pattern:**
```
main
```

**Enable de volgende opties:**

✅ **Require a pull request before merging**
   - Dit is de belangrijkste! Zonder PR kan niet mergen.

✅ **Require approvals**
   - Number of required approvals: `0` (jij bent de enige reviewer)
   - Of `1` als je jezelf wilt dwingen om PR's te reviewen

⚠️ **BELANGRIJK**: Zet deze AAN:
✅ **Do not allow bypassing the above settings**
   - Zelfs admins (jij) moeten PR's gebruiken

Optioneel (aanbevolen):
✅ **Require status checks to pass before merging**
   - Als je dit aanzet, moet Vercel preview build succesvol zijn
   - Zoek: `vercel` en selecteer de check

✅ **Require conversation resolution before merging**
   - Alle comments moeten resolved zijn

✅ **Require linear history**
   - Schonere git history (geen merge commits)
   - Of gebruik `--no-ff` voor duidelijkere release commits

### 4. Klik "Create" onderaan

Groene knop: **"Create"** of **"Save changes"**

### 5. Verificatie

Test of het werkt:

```bash
# Probeer direct te pushen naar main (zou MOETEN falen)
git checkout main
echo "test" >> test.txt
git add test.txt
git commit -m "test: direct push"
git push origin main
```

**Verwacht resultaat:**
```
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: error: Changes must be made through a pull request.
```

✅ Perfect! Branch protection werkt.

❌ Als push WEL lukt → check settings opnieuw

---

## ✅ Je bent klaar!

Vanaf nu:
- ❌ Direct pushen naar `main` = NIET MOGELIJK
- ✅ Alleen via Pull Request = JA

---

## 🔄 Nieuwe Workflow

Vanaf nu deploy je zo:

```bash
# 1. Ontwikkel in beta
git checkout beta
# ... maak wijzigingen ...
git add .
git commit -m "feat: nieuwe feature"
git push origin beta

# 2. Test op beta preview
# Open: movie-quest-git-beta-[user].vercel.app
# Test grondig!

# 3. Maak Pull Request (OP GITHUB):
# - Ga naar: https://github.com/Weirdhans/MovieQuest/pulls
# - Klik "New Pull Request"
# - Base: main ← Compare: beta
# - Klik "Create Pull Request"
# - Review de wijzigingen
# - Klik "Merge Pull Request"

# 4. Production is LIVE!
# Vercel deployed automatisch naar: movie-quests.vercel.app
```

---

## 🎁 Bonus: GitHub CLI (Optioneel)

Als je PR's wilt maken vanaf command line:

```bash
# Installeer GitHub CLI
# Windows: winget install GitHub.cli
# Of download: https://cli.github.com/

# Login
gh auth login

# Maak PR direct vanaf terminal
git checkout beta
git push origin beta
gh pr create --base main --head beta --title "feat: Christmas feature" --body "Adds Christmas movies filter"

# Merge PR
gh pr merge --squash --delete-branch
```

Maar via GitHub website is prima!

---

## 📱 GitHub Mobile App

Je kunt ook PR's maken/mergen vanaf je telefoon:
- Download: GitHub app (iOS/Android)
- Login → je repo → Pull Requests
- Swipe to merge! 😄

---

## ❓ FAQ

**Q: Kan ik dit later uitzetten?**
A: Ja! Settings → Branches → Edit rule → Delete rule

**Q: Wat als ik snel een hotfix moet doen?**
A: Maak PR, merge meteen (duurt 30 seconden). Branch protection voorkomt geen snelheid, alleen ongelukken!

**Q: Kan ik mezelf exemption geven?**
A: Ja, maar NIET DOEN. Het hele punt is dat je jezelf forceert om PR's te gebruiken.

---

## 🚨 Troubleshooting

**Probleem**: "I can still push to main"
**Oplossing**: Check of "Do not allow bypassing" is enabled

**Probleem**: "Vercel check not found"
**Oplossing**: Push naar beta eerst, wacht op Vercel build, dan pas enable status check

**Probleem**: "I accidentally pushed to main before setting this up"
**Oplossing**: No worries! Je kunt nu branch protection aanzetten, werkt vanaf nu.

---

Klaar! Main is nu beschermd 🛡️
