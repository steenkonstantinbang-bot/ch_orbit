# Udgiv ORBIT ZERO v1.5 på GitHub

Denne mappe er lavet til at være **roden af dit GitHub-repository**. Projektet er endnu ikke uploadet til nogen GitHub-konto.

## Anbefalet: Privat repository

Da det er et kommercielt spil under KONHAGEN GAMES, anbefales et **privat** repo som udgangspunkt.

### A. Brug GitHub CLI (hurtigst)

Installer GitHub CLI på Mac, hvis det mangler (`brew install gh`), og log ind med:

```bash
gh auth login
```

Åbn Terminal i denne udpakkede mappe, og kør:

```bash
git init
git branch -M main
git add .
git commit -m "ORBIT ZERO v1.5 – KONHAGEN GAMES"
gh repo create orbit-zero --private --source=. --remote=origin --push
git tag v1.5
git push origin v1.5
```

Hvis `git commit` beder om navn/mail, sæt dine egne Git-oplysninger med `git config user.name ...` og `git config user.email ...`.

### B. Uden GitHub CLI

1. Opret et **tomt, privat** repository på https://github.com/new med navnet `orbit-zero`. **Undlad** at tilføje README og `.gitignore` på GitHub, da de allerede følger med her.
2. Åbn Terminal i denne udpakkede mappe.
3. Erstat `DIT_BRUGERNAVN` i kommandoen nedenfor med dit GitHub-brugernavn:

```bash
git init
git branch -M main
git add .
git commit -m "ORBIT ZERO v1.5 – KONHAGEN GAMES"
git remote add origin https://github.com/DIT_BRUGERNAVN/orbit-zero.git
git push -u origin main
git tag v1.5
git push origin v1.5
```

GitHub kræver login ved push; brug fx Git Credential Manager eller GitHub CLI. En GitHub-adgangskode kan ikke normalt bruges direkte som Git-over-HTTPS password.

## Sådan opdaterer du senere

```bash
git add .
git commit -m "Opdater ORBIT ZERO"
git push
```

Før App Store-lancering: kør appen i Xcode, kontroller StoreKit-konfiguration og test køb via Apple Sandbox.
