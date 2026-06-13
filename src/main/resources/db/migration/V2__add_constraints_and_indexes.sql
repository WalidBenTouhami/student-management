-- V2: Add missing UNIQUE constraints and improve referential integrity
-- email must be unique per student (business rule)
ALTER TABLE student
    ADD CONSTRAINT uq_student_email UNIQUE (email);

-- course code must be unique (business rule: CS101, MATH201, etc.)
ALTER TABLE student
    MODIFY COLUMN first_name VARCHAR(100) NOT NULL,
    MODIFY COLUMN last_name  VARCHAR(100) NOT NULL,
    MODIFY COLUMN email      VARCHAR(320) NOT NULL;

ALTER TABLE course
    ADD CONSTRAINT uq_course_code UNIQUE (code),
    MODIFY COLUMN name VARCHAR(200) NOT NULL,
    MODIFY COLUMN code VARCHAR(20)  NOT NULL;

-- Add ON DELETE behavior for referential integrity
ALTER TABLE student
    DROP FOREIGN KEY fk_student_department,
    ADD CONSTRAINT fk_student_department
        FOREIGN KEY (department_id_department) REFERENCES department (id_department)
        ON DELETE SET NULL;

ALTER TABLE enrollment
    DROP FOREIGN KEY fk_enrollment_student,
    ADD CONSTRAINT fk_enrollment_student
        FOREIGN KEY (student_id_student) REFERENCES student (id_student)
        ON DELETE CASCADE,
    DROP FOREIGN KEY fk_enrollment_course,
    ADD CONSTRAINT fk_enrollment_course
        FOREIGN KEY (course_id_course) REFERENCES course (id_course)
        ON DELETE CASCADE;

-- Add index for common query patterns
CREATE INDEX idx_enrollment_student ON enrollment (student_id_student);
CREATE INDEX idx_enrollment_course ON enrollment (course_id_course);
CREATE INDEX idx_student_department ON student (department_id_department);
