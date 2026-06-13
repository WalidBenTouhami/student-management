-- V3: Add department association and capacity to courses
ALTER TABLE courses
    ADD COLUMN department_id BIGINT,
    ADD COLUMN capacity INT NOT NULL DEFAULT 30,
    ADD CONSTRAINT fk_course_department
        FOREIGN KEY (department_id) REFERENCES departments (id_department)
        ON DELETE SET NULL;

CREATE INDEX idx_course_department ON courses (department_id);
