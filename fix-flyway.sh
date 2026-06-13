#!/bin/bash
echo "🔧 Correction Flyway + Nettoyage..."

# 1. Nettoyage base de données de test (H2 ou MySQL locale)
echo "Suppression base de données de test..."
rm -f *.db *.mv.db 2>/dev/null || true

# 2. Réinitialisation Flyway (supprime l'historique des migrations)
echo "Réinitialisation historique Flyway..."
mysql -h localhost -u root -psecret -e "DROP DATABASE IF EXISTS studentdb;" 2>/dev/null || true
mysql -h localhost -u root -psecret -e "CREATE DATABASE studentdb;" 2>/dev/null || true

# 3. Nettoyage du projet
./mvnw clean

# 4. Correction du fichier V2 (éviter les noms de contraintes dupliqués)
echo "Correction du script V2__add_constraints_and_indexes.sql..."
cat > src/main/resources/db/migration/V2__add_constraints_and_indexes.sql << 'SQL'
-- V2 - Ajout contraintes et indexes (corrigé)

-- Contraintes sur Student
ALTER TABLE students 
ADD CONSTRAINT fk_student_department_unique 
FOREIGN KEY (department_id) REFERENCES departments(id_department);

-- Contraintes sur Course
ALTER TABLE courses 
ADD CONSTRAINT fk_course_department 
FOREIGN KEY (department_id) REFERENCES departments(id_department);

-- Contraintes sur Enrollment
ALTER TABLE enrollments 
ADD CONSTRAINT fk_enrollment_student 
FOREIGN KEY (student_id) REFERENCES students(id_student);

ALTER TABLE enrollments 
ADD CONSTRAINT fk_enrollment_course 
FOREIGN KEY (course_id) REFERENCES courses(id_course);

-- Indexes pour performances
CREATE INDEX idx_student_email ON students(email);
CREATE INDEX idx_student_department ON students(department_id);
CREATE INDEX idx_course_department ON courses(department_id);
CREATE INDEX idx_enrollment_student ON enrollments(student_id);
CREATE INDEX idx_enrollment_course ON enrollments(course_id);

-- Contraintes uniques
ALTER TABLE students ADD CONSTRAINT uk_student_email UNIQUE (email);
ALTER TABLE courses ADD CONSTRAINT uk_course_code UNIQUE (code);

SQL

echo "✅ Script V2 corrigé avec noms de contraintes uniques."

# 5. Build complet
echo "🚀 Lancement du build complet..."
./mvnw clean compile -U

echo "🧪 Lancement des tests..."
./mvnw verify -DskipITs=false --no-transfer-progress

echo "🎉 Correction terminée !"
