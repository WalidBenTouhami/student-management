# 🤝 Guide de Contribution (CONTRIBUTING.md)

Nous sommes ravis que vous souhaitiez contribuer au projet **Student Management** ! Ce document décrit le processus et les normes à suivre pour assurer la qualité et la stabilité du code.

---

## 🛠️ Processus de Contribution

1. **Forkez le dépôt** : Créez votre propre copie du projet sur GitHub.
2. **Créez une branche** : Ne travaillez jamais directement sur `main`. 
   ```bash
   $ git checkout -b feature/nom-de-la-fonctionnalite
   # ou
   $ git checkout -b fix/nom-du-bug
   ```
3. **Développez** : Écrivez votre code en respectant les standards de qualité ci-dessous.
4. **Testez localement** : Assurez-vous que tous les tests passent et que la compilation réussit.
5. **Commitez vos changements** : Rédigez des messages de commit clairs.
6. **Poussez votre branche** : `git push origin feature/nom-de-la-fonctionnalite`.
7. **Ouvrez une Pull Request (PR)** : Soumettez votre PR vers la branche `main` du dépôt d'origine.

---

## 📏 Standards de Code et Qualité

### 1. Code Java (Spring Boot)
* Respectez les conventions de nommage Java standard (CamelCase).
* Ajoutez des commentaires Javadoc pour les classes et méthodes complexes.
* L'architecture en couches doit être strictement respectée : **Controller -> Service -> Repository -> Entity**.

### 2. Tests Obligatoires (TDD fortement recommandé)
Toute nouvelle fonctionnalité **doit** être accompagnée de tests unitaires (JUnit / Mockito).
Le pipeline CI/CD (JaCoCo Quality Gate) rejettera toute PR qui fait chuter la couverture de code globale en dessous de **70%**.

Pour lancer les tests localement :
```bash
$ ./mvnw clean test
```

### 3. Conventions de nommage des Commits (Conventional Commits)
Utilisez des préfixes clairs pour vos commits :
* `feat:` : Nouvelle fonctionnalité.
* `fix:` : Correction d'un bug.
* `docs:` : Modification de la documentation (comme un README).
* `style:` : Formatage du code sans changement de logique (espaces, virgules, etc.).
* `refactor:` : Réécriture de code sans ajout de feature ni correction de bug.
* `test:` : Ajout ou modification de tests.
* `chore:` : Mise à jour de dépendances, scripts de build (ex: `pom.xml`, `Jenkinsfile`).

---

## 🔍 Processus de Revue (Code Review)

Avant que votre PR ne soit fusionnée (merge), elle passera par plusieurs étapes de validation :
1. **Validation Automatique (CI)** : Jenkins exécutera le pipeline (Build, Tests, SonarQube, Helm Lint). La PR ne pourra pas être fusionnée si le build échoue ou si SonarQube détecte de nouvelles vulnérabilités (Quality Gate en erreur).
2. **Revue par les Pairs** : Au moins un mainteneur (Senior DevOps/Dev) devra approuver votre code. Soyez ouvert aux retours et prêt à faire des ajustements.

---

## 📝 Liste de Contrôle (Checklist) pour les PR

Avant de soumettre votre PR, veuillez vérifier les points suivants :
- [ ] J'ai exécuté `mvn test` localement et tous les tests passent.
- [ ] Mon code n'introduit pas d'avertissements de compilation (warnings).
- [ ] J'ai mis à jour la documentation (`API.md` ou `README.md`) si j'ai modifié l'API ou l'infrastructure.
- [ ] Mes messages de commit respectent la convention.
- [ ] Je n'ai inclus aucun secret en clair (mot de passe, clé API, token) dans mon code.

Merci pour votre contribution ! 🎉
