CREATE TABLE department (
    id_department BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    location VARCHAR(255),
    phone VARCHAR(30),
    head VARCHAR(150),
    PRIMARY KEY (id_department)
);

CREATE TABLE course (
    id_course BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(30) NOT NULL,
    credit INT NOT NULL,
    description VARCHAR(1000),
    PRIMARY KEY (id_course),
    CONSTRAINT uk_course_code UNIQUE (code)
);

CREATE TABLE student (
    id_student BIGINT NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    date_of_birth DATE,
    address VARCHAR(255),
    department_id_department BIGINT,
    PRIMARY KEY (id_student),
    CONSTRAINT uk_student_email UNIQUE (email),
    CONSTRAINT fk_student_department FOREIGN KEY (department_id_department)
        REFERENCES department (id_department)
);

CREATE TABLE enrollment (
    id_enrollment BIGINT NOT NULL AUTO_INCREMENT,
    enrollment_date DATE NOT NULL,
    grade DOUBLE,
    status VARCHAR(30) NOT NULL,
    student_id_student BIGINT NOT NULL,
    course_id_course BIGINT NOT NULL,
    PRIMARY KEY (id_enrollment),
    CONSTRAINT uk_enrollment_student_course UNIQUE (student_id_student, course_id_course),
    CONSTRAINT fk_enrollment_student FOREIGN KEY (student_id_student)
        REFERENCES student (id_student),
    CONSTRAINT fk_enrollment_course FOREIGN KEY (course_id_course)
        REFERENCES course (id_course)
);
