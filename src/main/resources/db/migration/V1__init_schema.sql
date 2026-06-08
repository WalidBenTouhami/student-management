CREATE TABLE department (
    id_department   BIGINT       NOT NULL AUTO_INCREMENT,
    name            VARCHAR(255) NOT NULL,
    location        VARCHAR(255),
    phone           VARCHAR(255),
    head            VARCHAR(255),
    PRIMARY KEY (id_department)
);

CREATE TABLE student (
    id_student              BIGINT       NOT NULL AUTO_INCREMENT,
    first_name              VARCHAR(255) NOT NULL,
    last_name               VARCHAR(255) NOT NULL,
    email                   VARCHAR(255) NOT NULL,
    phone                   VARCHAR(255),
    date_of_birth           DATE,
    address                 VARCHAR(255),
    department_id_department BIGINT,
    PRIMARY KEY (id_student),
    CONSTRAINT fk_student_department
        FOREIGN KEY (department_id_department) REFERENCES department (id_department)
);

CREATE TABLE course (
    id_course   BIGINT       NOT NULL AUTO_INCREMENT,
    name        VARCHAR(255) NOT NULL,
    code        VARCHAR(255) NOT NULL,
    credit      INT          NOT NULL DEFAULT 0,
    description VARCHAR(255),
    PRIMARY KEY (id_course)
);

CREATE TABLE enrollment (
    id_enrollment      BIGINT       NOT NULL AUTO_INCREMENT,
    enrollment_date    DATE         NOT NULL,
    grade              DOUBLE,
    status             VARCHAR(50)  NOT NULL,
    student_id_student BIGINT,
    course_id_course   BIGINT,
    PRIMARY KEY (id_enrollment),
    CONSTRAINT fk_enrollment_student
        FOREIGN KEY (student_id_student) REFERENCES student (id_student),
    CONSTRAINT fk_enrollment_course
        FOREIGN KEY (course_id_course) REFERENCES course (id_course)
);
