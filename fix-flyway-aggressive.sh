#!/bin/bash
echo "🔥 Correction AGRESSIVE Flyway + Reset complet..."

# 1. Arrêt propre
pkill -f spring-boot || true

# 2. Nettoyage total
./mvnw clean
rm -rf target/
rm -rf ~/.m2/repository/tn/esprit/studentmanagement/

# 3. Reset complet de la base de données MySQL
echo "🗑️  Suppression et recréation de la base studentdb..."
mysql -h localhost -u root -psecret -e "
    DROP DATABASE IF EXISTS studentdb;
    CREATE DATABASE studentdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    GRANT ALL PRIVILEGES ON studentdb.* TO 'root'@'%';
    FLUSH PRIVILEGES;
" 2>/dev/null || echo "⚠️ MySQL non accessible (normal si H2 utilisé en test)"

# 4. Réécriture propre du script V2
cat > src/main/resources/db/migration/V2__add_constraints_and_indexes.sql << 'SQL'
-- V2 - Contraintes et indexes (Version propre et idempotente)

-- Student -> Department
ALTER TABLE students 
ADD CONSTRAINT IF NOT EXISTS fk_student_department 
FOREIGN KEY (department_id) REFERENCES departments(id_department);

-- Course -> Department
ALTER TABLE courses 
ADD CONSTRAINT IF NOT EXISTS fk_course_department 
FOREIGN KEY (department_id) REFERENCES departments(id_department);

-- Enrollment -> Student
ALTER TABLE enrollments 
ADD CONSTRAINT IF NOT EXISTS fk_enrollment_student 
FOREIGN KEY (student_id) REFERENCES students(id_student);

-- Enrollment -> Course
ALTER TABLE enrollments 
ADD CONSTRAINT IF NOT EXISTS fk_enrollment_course 
FOREIGN KEY (course_id) REFERENCES courses(id_course);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_students_email ON students(email);
CREATE INDEX IF NOT EXISTS idx_students_dept ON students(department_id);
CREATE INDEX IF NOT EXISTS idx_courses_dept ON courses(department_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON enrollments(course_id);

-- Contraintes uniques
ALTER TABLE students ADD CONSTRAINT IF NOT EXISTS uk_students_email UNIQUE (email);
ALTER TABLE courses ADD CONSTRAINT IF NOT EXISTS uk_courses_code UNIQUE (code);

SQL

echo "✅ V2 corrigé avec IF NOT EXISTS"

# 5. Build + Tests
echo "🚀 Compilation..."
./mvnw clean compile -U --no-transfer-progress

echo "🧪 Tests complets..."
./mvnw verify --no-transfer-progress -Dspring.profiles.active=test

echo "🎉 Correction terminée !"
echo "Lancement de l'application :"
echo "./mvnw spring-boot:run -Dspring.profiles.active=dev"
