-- ============================================================
-- V1 — Initial Schema
-- Table names MUST match JPA @Table(name=...) annotations:
--   students, departments, courses, enrollments
-- FK columns MUST match JPA @JoinColumn(name=...) defaults:
--   department_id, student_id, course_id
-- ============================================================

CREATE TABLE departments (
    id_department BIGINT       NOT NULL AUTO_INCREMENT,
    name          VARCHAR(255) NOT NULL,
    location      VARCHAR(255),
    phone         VARCHAR(50),
    head          VARCHAR(255),
    PRIMARY KEY (id_department)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE students (
    id_student    BIGINT       NOT NULL AUTO_INCREMENT,
    first_name    VARCHAR(255) NOT NULL,
    last_name     VARCHAR(255) NOT NULL,
    email         VARCHAR(320) NOT NULL,
    phone         VARCHAR(50),
    date_of_birth DATE,
    address       VARCHAR(255),
    department_id BIGINT,
    PRIMARY KEY (id_student),
    CONSTRAINT fk_student_department
        FOREIGN KEY (department_id) REFERENCES departments (id_department)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE courses (
    id_course   BIGINT       NOT NULL AUTO_INCREMENT,
    name        VARCHAR(200) NOT NULL,
    code        VARCHAR(20)  NOT NULL,
    credit        INT          NOT NULL DEFAULT 0,
    description   VARCHAR(500),
    department_id BIGINT,
    PRIMARY KEY (id_course)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE enrollments (
    id_enrollment   BIGINT      NOT NULL AUTO_INCREMENT,
    enrollment_date DATE        NOT NULL,
    grade           DOUBLE,
    status          VARCHAR(20) NOT NULL,
    student_id      BIGINT,
    course_id       BIGINT,
    PRIMARY KEY (id_enrollment),
    CONSTRAINT fk_enrollment_student
        FOREIGN KEY (student_id) REFERENCES students (id_student),
    CONSTRAINT fk_enrollment_course
        FOREIGN KEY (course_id) REFERENCES courses (id_course)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
