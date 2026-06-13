-- V3: Add department association and capacity to courses
ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS department_id BIGINT,
    ADD COLUMN IF NOT EXISTS capacity INT NOT NULL DEFAULT 30;

ALTER TABLE courses
    ADD CONSTRAINT fk_course_department
        FOREIGN KEY (department_id) REFERENCES departments (id_department)
        ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_courses_dept ON courses(department_id);

