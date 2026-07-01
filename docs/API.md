# 🔌 Documentation de l'API REST (API.md)

L'API de **Student Management** suit les standards RESTful et permet de gérer les entités principales du système : Étudiants, Départements et Inscriptions (Enrollments).

**Base URL** : `http://<IP_DU_SERVEUR>:<PORT>/student`
*(En local avec Kubernetes via NodePort : `http://192.168.56.10:30089/student`)*

---

## 👩‍🎓 Étudiants (Students)

### 1. Récupérer tous les étudiants
* **Méthode** : `GET`
* **Chemin** : `/students`
* **Exemple cURL** :
  ```bash
  curl -X GET http://192.168.56.10:30089/student/students
  ```
* **Réponse Succès (200 OK)** :
  ```json
  [
    {
      "idStudent": 1,
      "firstName": "Alice",
      "lastName": "Dupont",
      "email": "alice@esprit.tn"
    }
  ]
  ```

### 2. Ajouter un étudiant
* **Méthode** : `POST`
* **Chemin** : `/students`
* **Exemple cURL** :
  ```bash
  curl -X POST http://192.168.56.10:30089/student/students \
       -H "Content-Type: application/json" \
       -d '{"firstName":"Bob", "lastName":"Martin", "email":"bob@esprit.tn"}'
  ```
* **Réponse Succès (201 Created)** : L'objet créé avec son ID.

### 3. Modifier un étudiant
* **Méthode** : `PUT`
* **Chemin** : `/students/{id}`
* **Exemple cURL** :
  ```bash
  curl -X PUT http://192.168.56.10:30089/student/students/1 \
       -H "Content-Type: application/json" \
       -d '{"firstName":"Alice", "lastName":"Durand", "email":"alice.durand@esprit.tn"}'
  ```

### 4. Supprimer un étudiant
* **Méthode** : `DELETE`
* **Chemin** : `/students/{id}`
* **Exemple cURL** :
  ```bash
  curl -X DELETE http://192.168.56.10:30089/student/students/1
  ```
* **Réponse Succès (204 No Content)** : Vide.

---

## 🏢 Départements (Departments)

L'API Départements fonctionne exactement sur le même principe CRUD.

* `GET /departments` : Liste des départements.
* `GET /departments/{id}` : Récupère un département spécifique.
* `POST /departments` : Crée un département.
  * *Exemple Payload:* `{"name": "Informatique", "code": "INFO"}`
* `PUT /departments/{id}` : Modifie un département.
* `DELETE /departments/{id}` : Supprime un département.

---

## 📝 Inscriptions (Enrollments)

L'API d'inscriptions permet d'associer des étudiants à des cours ou départements.

* `GET /enrollments` : Liste des inscriptions.
* `GET /enrollments/{id}` : Détail d'une inscription.
* `POST /enrollments` : Crée une inscription.
  * *Exemple Payload:* `{"studentId": 1, "courseId": 101, "enrollmentDate": "2026-09-01"}`
* `PUT /enrollments/{id}` : Modifie une inscription.
* `DELETE /enrollments/{id}` : Supprime une inscription.

---

## 🛡️ Sécurité & Swagger

### Documentation Interactive (Swagger / OpenAPI)
L'API est auto-documentée via Springdoc OpenAPI. Vous pouvez tester les requêtes directement depuis l'interface web :
* **URL Swagger UI** : `http://192.168.56.10:30089/student/swagger-ui.html`
* **URL OpenAPI JSON** : `http://192.168.56.10:30089/student/api-docs`

### Authentification
* Les endpoints d'affaires (Étudiants, Départements) sont publics par défaut (selon la configuration de sécurité Spring actuelle).
* L'endpoint Actuator/Prometheus (`/actuator/prometheus`) est **sécurisé par Basic Auth** pour éviter les fuites de données d'infrastructure.
