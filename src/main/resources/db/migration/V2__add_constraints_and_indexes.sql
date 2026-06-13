-- V2: Add missing UNIQUE constraints and improve referential integrity
-- email must be unique per student (business rule)
ALTER TABLE students
    ADD CONSTRAINT uq_student_email UNIQUE (email);

-- Modify column sizes and nullability
ALTER TABLE students
    MODIFY COLUMN first_name VARCHAR(100) NOT NULL,
    MODIFY COLUMN last_name  VARCHAR(100) NOT NULL,
    MODIFY COLUMN email      VARCHAR(320) NOT NULL;

-- course code must be unique
ALTER TABLE courses
    ADD CONSTRAINT uq_course_code UNIQUE (code),
    MODIFY COLUMN name VARCHAR(200) NOT NULL,
    MODIFY COLUMN code VARCHAR(20)  NOT NULL;

-- Add ON DELETE behavior for referential integrity
ALTER TABLE students
    DROP FOREIGN KEY fk_student_department,
    ADD CONSTRAINT fk_student_department
        FOREIGN KEY (department_id) REFERENCES departments (id_department)
        ON DELETE SET NULL;

ALTER TABLE enrollments
    DROP FOREIGN KEY fk_enrollment_student,
    ADD CONSTRAINT fk_enrollment_student
        FOREIGN KEY (student_id) REFERENCES students (id_student)
        ON DELETE CASCADE,
    DROP FOREIGN KEY fk_enrollment_course,
    ADD CONSTRAINT fk_enrollment_course
        FOREIGN KEY (course_id) REFERENCES courses (id_course)
        ON DELETE CASCADE;

-- Add index for common query patterns
CREATE INDEX idx_enrollment_student ON enrollments (student_id);
CREATE INDEX idx_enrollment_course ON enrollments (course_id);
CREATE INDEX idx_student_department ON students (department_id);
