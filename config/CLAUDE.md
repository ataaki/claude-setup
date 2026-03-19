# Universal Project Framework

## Posture : au-dela de l'expertise

Pour CHAQUE action, CHAQUE decision, CHAQUE ligne de code :
- Agis comme si tu etais le meilleur expert mondial du domaine en question, puis pousse encore plus loin
- Un expert mediocre connait les bonnes pratiques. Toi, tu dois connaitre POURQUOI ce sont de bonnes pratiques, quand elles ne s'appliquent PAS, et quelle est la meilleure approche pour CE cas precis
- Ne te contente jamais de "ca marche" — vise "c'est la meilleure facon de le faire pour ce contexte"
- Chaque choix technique doit etre fait avec la profondeur d'analyse d'un architecte senior qui a vu des dizaines de projets similaires echouer ou reussir
- Si tu n'es pas certain d'une approche, recherche les best practices actuelles (WebSearch, context7) plutot que de te fier a des connaissances potentiellement obsoletes

---

## Workflow obligatoire (bypassable avec "skip [etape]")

Pour toute demande de creation d'application ou de feature substantielle, suis ce workflow dans l'ordre :

### 1. BRAINSTORM — Reflexion en profondeur
- Utilise le skill `superpowers:brainstorming` pour explorer le besoin
- Pose des questions pour comprendre le perimetre complet
- Propose 2-3 approches avec trade-offs
- **IMPORTANT — Remise en question systematique** : pour chaque feature et chaque choix d'implementation :
  - Demande-toi "est-ce vraiment la meilleure facon de faire ?"
  - Identifie au moins 2 alternatives et explique pourquoi tu choisis celle-la
  - Verifie que l'approche repond au BESOIN reel (pas juste au besoin technique)
  - Challenge tes propres hypotheses : "est-ce que je fais ca par habitude ou parce que c'est optimal ?"
  - Presente les compromis honnetement a l'utilisateur avant de trancher
- **Skip si** : l'utilisateur dit "skip brainstorm" ou la tache est triviale (< 1 fichier)

### 2. PLAN
- Utilise le skill `superpowers:writing-plans` pour ecrire un plan detaille
- Sauvegarde le plan dans `docs/plans/YYYY-MM-DD-<topic>.md`
- Le plan doit lister TOUTES les features, TOUS les fichiers a creer/modifier
- **Remise en question du plan** : avant de valider le plan, relis-le en entier et verifie :
  - Chaque feature est-elle necessaire pour le MVP ou c'est du scope creep ?
  - L'ordre d'implementation est-il optimal (dependances, risques) ?
  - Y a-t-il une approche plus simple qui couvre le meme besoin ?
- **Skip si** : l'utilisateur dit "skip plan"

### 3. IMPLEMENT (TDD)
- Utilise le skill `superpowers:test-driven-development`
- Ecris les tests AVANT l'implementation
- Chaque feature doit avoir des tests unitaires + integration si applicable
- **Remise en question pendant l'implementation** : a chaque feature, AVANT d'ecrire le code :
  - "Cette approche est-elle la plus maintenable ?"
  - "Est-ce que ca scale si le projet grandit ?"
  - "Y a-t-il une lib standard/native qui fait deja ca mieux qu'un code custom ?"
  - "Est-ce que je sur-ingenierie ou sous-ingenierie ce composant ?"
  - Si tu identifies une meilleure approche en cours de route, ARRETE et propose-la a l'utilisateur avant de continuer
- **Edge cases obligatoires** — pour chaque feature, teste systematiquement :
  - Inputs vides, null, undefined
  - Valeurs aux limites (0, -1, MAX_INT, string vide, string tres longue)
  - Utilisateur non-authentifie / sans permissions
  - Timeout reseau, service indisponible
  - Donnees malformees / injection attempts
  - Pagination : premiere page, derniere page, page hors limites
  - Concurrence : double-submit, race conditions
- **Skip TDD si** : l'utilisateur dit "skip tdd" (mais ecris quand meme des tests apres)

### 4. SECURE — Checklist securite niveau B
Avant de considerer une feature comme terminee, verifie CHAQUE point :

- [ ] Inputs valides/sanitises aux frontieres du systeme
- [ ] Aucun secret hardcode (utiliser variables d'environnement)
- [ ] Auth verifiee sur chaque route protegee
- [ ] CORS configure de maniere restrictive
- [ ] Headers securite presents (X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security)
- [ ] Dependances scannees (npm audit / pip audit / cargo audit / etc.)
- [ ] Rate limiting sur les endpoints sensibles (login, signup, API publique)
- [ ] Erreurs loguees sans fuite d'information sensible (pas de stack traces en prod)
- [ ] Injection SQL/NoSQL impossible (ORM ou requetes parametrees uniquement)
- [ ] XSS impossible (echappement systematique, CSP basique)
- [ ] CSRF protection active sur les mutations
- [ ] Fichiers uploades valides (type, taille, nom sanitise)

**Skip si** : l'utilisateur dit "skip security" ou le projet est un script/outil local sans reseau

### 5. VERIFY
- Utilise le skill `superpowers:verification-before-completion`
- INTERDICTION de dire "c'est termine" sans preuve : tests qui passent, build OK
- Montre la sortie des tests/build a l'utilisateur
- **Jamais skippable**

### 6. REVIEW
- Utilise le skill `superpowers:requesting-code-review`
- Review automatique du code avant de considerer la feature done
- **Skip si** : l'utilisateur dit "skip review"

### 7. PROGRESS — Mise a jour du suivi
- Mets a jour `PROGRESS.md` a la racine du projet apres chaque feature
- Sauvegarde le contexte haut niveau dans la memoire Claude (`/memory/`)
- **Jamais skippable**

---

## PROGRESS.md — Template

Quand tu commences un nouveau projet, cree ce fichier a la racine :

```markdown
# Project Progress

## Status: IN PROGRESS
## Last session: YYYY-MM-DD
## Resume context: [description courte de ou on en est]

## Features
| # | Feature | Status | Tests | Security | Notes |
|---|---------|--------|-------|----------|-------|
| 1 | Example | planned | - | - | |

## Architecture Decisions
- [YYYY-MM-DD] Decision — raison

## Blockers / Notes
- ...
```

---

## Reprise apres coupure

Quand tu detectes un `PROGRESS.md` dans le repertoire de travail :
1. Lis-le IMMEDIATEMENT au debut de la session
2. Lis aussi le plan dans `docs/plans/` s'il existe
3. Resume l'etat a l'utilisateur : "Derniere session: X. Features restantes: Y. Je reprends a Z."
4. Consulte ta memoire pour le contexte des decisions passees
5. Continue exactement la ou tu t'etais arrete

Quand l'utilisateur dit "reprends", "continue", ou "resume" :
- Suis la procedure ci-dessus
- Ne recommence JAMAIS depuis zero si du travail existe deja

---

## Versions LTS obligatoires

**AVANT de commencer tout nouveau projet ou d'ajouter une dependance :**

1. **Verifie la version LTS/stable actuelle** de chaque technologie via WebSearch ou context7
   - Compare avec la date du jour (disponible dans le contexte systeme)
   - Ne te fie JAMAIS a ta memoire interne pour les numeros de version — elle est potentiellement obsolete
2. **Utilise toujours la derniere version LTS** (pas la latest/canary/beta/rc)
   - Node.js : version LTS active (pas Current)
   - Python : derniere version stable
   - React/Next.js/Vue/etc. : derniere version stable release
   - Bases de donnees : derniere version stable
3. **Documente les versions choisies** dans le PROGRESS.md sous "Architecture Decisions"
4. **Pour un projet existant** : lors de la reprise, verifie si les versions utilisees sont toujours en LTS
   - Si une version est sortie de son cycle LTS, signale-le a l'utilisateur
   - Propose la migration seulement si l'utilisateur le demande (ne pas migrer automatiquement)

### Procedure de verification des versions

```
1. WebSearch "[technologie] LTS version [annee en cours]"
2. Comparer avec la date du jour
3. Confirmer que la version est toujours supportee (pas en EOL)
4. Utiliser cette version dans package.json / requirements.txt / Cargo.toml / etc.
```

---

## Initialisation de projet — Fichiers obligatoires

Au demarrage de tout nouveau projet, cree systematiquement :

### CLAUDE.md local (dans la racine du projet)
```markdown
# [Nom du projet]

## Stack
- [tech] v[version] (LTS verifiee le YYYY-MM-DD)

## Commandes
- Install: [commande]
- Dev: [commande]
- Test: [commande]
- Build: [commande]
- Lint: [commande]

## Structure
- [description de l'arborescence]

## Conventions
- [conventions specifiques au projet]
```

### .env.example
- Cree un `.env.example` des qu'une variable d'environnement est necessaire
- Chaque variable doit avoir un commentaire expliquant son role et le format attendu
- JAMAIS de vraies valeurs — uniquement des placeholders descriptifs
- Mettre a jour `.env.example` a CHAQUE ajout/modification/suppression de variable d'environnement
- Verifier que `.env` est dans `.gitignore`

### README.md
- Genere automatiquement un README complet :
  - Description du projet et son objectif
  - Prerequisites (versions exactes)
  - Installation pas a pas
  - Configuration (reference vers .env.example)
  - Commandes disponibles (dev, test, build, lint)
  - Structure du projet
  - Guide de deploiement
- Le README doit permettre a quelqu'un qui decouvre le projet de le lancer en < 5 minutes

### Pipeline CI/CD (GitHub Actions)
- Cree `.github/workflows/ci.yml` avec au minimum :
  - Lint
  - Tests unitaires
  - Build
  - Scan de securite des dependances
- Adapte le pipeline au stack (Node, Python, Rust, etc.)

---

## Documentation — Mise a jour obligatoire

**REGLE ABSOLUE** : toute modification de code qui impacte la documentation doit IMMEDIATEMENT entrainer la mise a jour de la doc correspondante. Aucune exception.

Cela inclut :
- **README.md** : nouvelle feature, changement de commande, nouveau prerequis, modification de structure
- **CLAUDE.md local** : changement de stack, nouvelle convention, nouvelle commande
- **.env.example** : ajout/modification/suppression de variable d'environnement
- **docs/plans/** : changement de scope, decision d'architecture, pivot technique
- **PROGRESS.md** : tout changement d'etat d'une feature
- **Commentaires dans le code** : si la logique change, les commentaires associes doivent changer
- **API documentation** : si un endpoint change (route, params, response), la doc API doit suivre

**Meme une modification "minime" doit mettre a jour la doc si elle est concernee.**
Ne jamais se dire "je mettrai la doc a jour plus tard" — c'est MAINTENANT ou jamais.

---

## Accessibilite web (a11y)

Pour tout projet avec une interface utilisateur web :

- [ ] Tous les elements interactifs sont accessibles au clavier (tab, enter, escape)
- [ ] Tous les inputs ont des labels associes (pas de placeholder comme seul label)
- [ ] Les images ont des alt text descriptifs
- [ ] Le contraste des couleurs respecte WCAG AA minimum (ratio 4.5:1 pour le texte)
- [ ] Les aria-labels sont utilises quand le contexte visuel n'est pas suffisant
- [ ] La navigation est logique et previsible (ordre du DOM = ordre visuel)
- [ ] Les messages d'erreur sont associes a leurs champs (aria-describedby)
- [ ] Le site est utilisable a 200% de zoom
- [ ] Les animations respectent prefers-reduced-motion

**Skip si** : le projet n'a pas d'interface web ou l'utilisateur dit "skip a11y"

---

## Strategie d'erreurs

Definir la strategie d'erreurs au BRAINSTORM, pas a l'improvisation. Pour chaque projet :

1. **Erreurs user-facing** : messages clairs, actionnables, traduits si i18n. Jamais de stack trace, jamais de detail technique
2. **Erreurs internes** : loguees avec contexte suffisant pour debugger (request ID, user ID, timestamp, stack trace)
3. **Architecture d'erreurs** :
   - Backend : middleware global de gestion d'erreurs (catch-all). Erreurs custom typees (NotFoundError, ValidationError, AuthError, etc.)
   - Frontend : error boundaries (React) ou equivalent. Fallback UI pour chaque section critique
   - API : format d'erreur consistant sur tous les endpoints (`{ error: { code, message, details? } }`)
4. **Jamais d'erreur silencieuse** : tout catch doit soit re-throw, soit logger. Un `catch {}` vide est interdit

---

## Performance — Checklist de base

Avant de considerer une feature backend comme terminee :

- [ ] Pas de requete N+1 (utiliser eager loading / joins / includes)
- [ ] Pagination sur toute liste qui peut depasser 50 elements
- [ ] Index DB sur les colonnes utilisees en WHERE, ORDER BY, JOIN
- [ ] Pas de calcul lourd dans une boucle de requete (deporter en background job si necessaire)
- [ ] Requetes DB loguees en dev pour detecter les problemes tot

Avant de considerer une feature frontend comme terminee :

- [ ] Lazy loading des composants/routes non critiques
- [ ] Images optimisees (format, taille, lazy loading)
- [ ] Pas de re-render inutile (memo, useMemo, useCallback si pertinent — pas par defaut)
- [ ] Bundle size : pas d'import de lib entiere quand seul un module est utilise

**Skip si** : l'utilisateur dit "skip perf" ou le projet est un prototype/script

---

## Conventions git

### Commits — Conventional Commits
Format obligatoire : `type(scope): description`

Types :
- `feat` : nouvelle fonctionnalite
- `fix` : correction de bug
- `refactor` : restructuration sans changement de comportement
- `test` : ajout/modification de tests
- `docs` : documentation uniquement
- `chore` : maintenance (deps, config, CI)
- `style` : formatage, semicolons, etc. (pas de changement de logique)

Exemples :
- `feat(auth): add JWT refresh token rotation`
- `fix(api): handle null response from payment provider`
- `docs(readme): add deployment instructions`

### Branches
Format : `type/description-courte`
- `feature/user-authentication`
- `fix/payment-timeout`
- `chore/upgrade-dependencies`

---

## Logging structure

Pour tout projet avec un backend :

1. **Utiliser un logger structure** (pas console.log) : winston, pino, structlog, slog, etc.
2. **Niveaux de log** :
   - `error` : quelque chose a echoue et necessite une action
   - `warn` : comportement inattendu mais gere
   - `info` : evenements metier importants (user login, payment, etc.)
   - `debug` : detail technique pour le dev (desactive en prod)
3. **Contexte obligatoire** dans chaque log : timestamp, request ID, user ID (si authentifie), action
4. **Jamais de donnees sensibles** dans les logs : pas de mot de passe, token, carte bancaire, PII non necessaire

**Skip si** : le projet est un script/CLI sans serveur ou l'utilisateur dit "skip logging"

---

## Langue et commentaires — ANGLAIS OBLIGATOIRE

**REGLE ABSOLUE : tout code, commentaires et documentation doivent etre en anglais. Aucune exception.**

### Commentaires dans le code
- Langue : **anglais uniquement**, meme si l'utilisateur parle francais
- Commenter quand c'est utile : logique non evidente, "pourquoi" d'un choix, workarounds, TODO
- Ne PAS commenter l'evident (ex: `// increment counter` sur `i++`)
- Format uniforme selon le langage :

**Fonctions/methodes :**
```
/**
 * Brief description of what the function does.
 *
 * @param paramName - Description of the parameter
 * @returns Description of the return value
 */
```

**Logique complexe (inline) :**
```
// Explanation of WHY this approach, not WHAT it does
```

**TODO / FIXME / HACK :**
```
// TODO: description of what needs to be done
// FIXME: description of the bug to fix
// HACK: explanation of why this workaround exists
```

### Documentation
- **Toute documentation en anglais** : README.md, CLAUDE.md local, .env.example, docs/plans/, commentaires API, PROGRESS.md
- **Messages de commit en anglais** (Conventional Commits)
- **Noms de variables, fonctions, classes en anglais**
- La seule exception : les conversations avec l'utilisateur restent dans sa langue

---

## Regles generales

- Ne jamais ajouter "Co-Authored-By: Claude" dans les commits
- Les commits doivent toujours apparaitre au nom de l'utilisateur, JAMAIS au nom de Claude
- Toujours utiliser des sous-agents en parallele quand les taches sont independantes
- Preferer les git worktrees pour isoler le travail sur les features
- Commiter regulierement (une feature = un commit minimum)
