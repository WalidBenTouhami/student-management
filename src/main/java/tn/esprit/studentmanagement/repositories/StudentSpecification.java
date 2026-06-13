package tn.esprit.studentmanagement.repositories;

import org.springframework.data.jpa.domain.Specification;
import tn.esprit.studentmanagement.entities.Student;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;

public class StudentSpecification {

    public static Specification<Student> search(String name, String email, String departmentName, Long departmentId) {
        return (root, query, cb) -> {
            jakarta.persistence.criteria.Predicate predicate = cb.conjunction();

            if (name != null && !name.trim().isEmpty()) {
                String likeName = "%" + name.trim().toLowerCase() + "%";
                predicate = cb.and(predicate, cb.or(
                        cb.like(cb.lower(root.get("firstName")), likeName),
                        cb.like(cb.lower(root.get("lastName")), likeName)
                ));
            }

            if (email != null && !email.trim().isEmpty()) {
                predicate = cb.and(predicate, cb.like(cb.lower(root.get("email")), "%" + email.trim().toLowerCase() + "%"));
            }

            if (departmentId != null) {
                predicate = cb.and(predicate, cb.equal(root.get("department").get("idDepartment"), departmentId));
            } else if (departmentName != null && !departmentName.trim().isEmpty()) {
                Join<Student, Object> departmentJoin = root.join("department", JoinType.LEFT);
                predicate = cb.and(predicate, cb.like(cb.lower(departmentJoin.get("name")), "%" + departmentName.trim().toLowerCase() + "%"));
            }

            return predicate;
        };
    }
}
