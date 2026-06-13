# FIXES APPLIED

This document outlines all interventions performed to resolve issues discovered during the DevOps and Security audits.

## 1. Database & Migrations
- **Flyway Reactivation**: Removed `spring.flyway.enabled=false` workaround and ensured `baseline-on-migrate=true`.
- **Schema Alignment**: Added `department_id` directly in `V1__init_schema.sql` for the `courses` table to reflect JPA models correctly from the start.
- **Foreign Key Relocation**: Adjusted `V3__add_course_department_and_capacity.sql` to strictly add the `fk_course_department` constraint and `capacity` column.
- **MySQL Configuration**: Handled `Public Key Retrieval is not allowed` by retaining `allowPublicKeyRetrieval=true` in connection strings.

## 2. Code Quality & Persistence
- **MapStruct Integrity**: Fixed cyclic reference mappings and updated DTO mappers (`StudentMapper`, `CourseMapper`, `DepartmentMapper`) to gracefully ignore missing relational objects (thus fixing `TransientObjectException` on inserts).
- **Transactions (`@Transactional`)**: Added `@Transactional` to `CourseService`, `DepartmentService`, `EnrollmentService`, `StatsService`, and `StudentService`. Read-only methods (e.g., `getAll()`) use `@Transactional(readOnly = true)`.
- **Pagination (`Pageable`)**: Converted all Controller and Service `getAll()` methods from returning flat `List<DTO>` to `Page<DTO>` with `page` and `size` request parameters to prevent database out-of-memory errors on large datasets.

## 3. DevOps & Secrets Hardening
- **Environment Variables**: Replaced hardcoded `root`/`root` credentials in `docker-compose.yml` and `application-prod.properties` with `${DB_USER}` and `${DB_PASSWORD}`.
- **.env Template**: Created `.env.example` as a baseline for deployments.
- **Docker Multi-Stage**: Verified `Dockerfile` already leverages `eclipse-temurin:21-jre-alpine` and sets `USER appuser` to respect Pod Security Standards.
- **CI/CD Pipeline**: Configured `.github/workflows/ci-cd.yml` with Maven test caching and Docker image build steps.

## 4. End-To-End Tests
- **E2E Authentication Fixes**: Reconciled `StudentManagementE2ETest` to accommodate `Enrollment` validation (`enrollmentDate`, `courseId`). Resolved null-pointer assertion crashes on HTTP 401.
