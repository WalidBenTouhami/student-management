-- V2 - Contraintes et indexes (Version propre et idempotente)

-- Student -> Department
ALTER TABLE students 
ADD CONSTRAINT IF NOT EXISTS fk_student_department 
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
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON enrollments(course_id);

-- Contraintes uniques
ALTER TABLE students ADD CONSTRAINT IF NOT EXISTS uk_students_email UNIQUE (email);
ALTER TABLE courses ADD CONSTRAINT IF NOT EXISTS uk_courses_code UNIQUE (code);

