#!/bin/bash
echo "🔧 Correction définitive Flyway..."

# 1. Nettoyage complet
./mvnw clean
rm -rf target/

# 2. Réinitialisation base de données (pour tests)
echo "Réinitialisation base de données..."
mysql -h localhost -u root -psecret -e "DROP DATABASE IF EXISTS studentdb;" 2>/dev/null || true
mysql -h localhost -u root -psecret -e "CREATE DATABASE IF NOT EXISTS studentdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" || true

# 3. Correction du script V2 (noms de contraintes uniques)
cat > src/main/resources/db/migration/V2__add_constraints_and_indexes.sql << 'SQL'
-- V2__add_constraints_and_indexes.sql (Version corrigée)

-- Contraintes sur students
ALTER TABLE students 
ADD CONSTRAINT fk_student_department 
FOREIGN KEY (department_id) REFERENCES departments(id_department);

-- Contraintes sur courses
ALTER TABLE courses 
ADD CONSTRAINT fk_course_department 
FOREIGN KEY (department_id) REFERENCES departments(id_department);

-- Contraintes sur enrollments
ALTER TABLE enrollments 
ADD CONSTRAINT fk_enrollment_student 
FOREIGN KEY (student_id) REFERENCES students(id_student);

ALTER TABLE enrollments 
ADD CONSTRAINT fk_enrollment_course 
FOREIGN KEY (course_id) REFERENCES courses(id_course);

-- Indexes de performance
CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_students_department_id ON students(department_id);
CREATE INDEX idx_courses_department_id ON courses(department_id);
CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_enrollments_course_id ON enrollments(course_id);

-- Contraintes uniques
ALTER TABLE students ADD CONSTRAINT uk_students_email UNIQUE (email);
ALTER TABLE courses ADD CONSTRAINT uk_courses_code UNIQUE (code);

SQL

echo "✅ Script V2 corrigé avec noms de contraintes uniques."

# 4. Build complet
echo "🚀 Compilation + Tests..."
./mvnw clean compile -U

echo "🧪 Exécution des tests..."
./mvnw verify --no-transfer-progress

echo "🎉 Correction terminée !"
echo "Tu peux maintenant lancer l'application avec : ./mvnw spring-boot:run -Dspring.profiles.active=dev"
