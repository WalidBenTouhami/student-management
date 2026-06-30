package tn.esprit.studentmanagement.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.DepartmentDTO;
import tn.esprit.studentmanagement.services.IDepartmentService;

import java.util.List;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/departments")
public class DepartmentController {
    private IDepartmentService departmentService;

    public DepartmentController(IDepartmentService departmentService) {
        this.departmentService = departmentService;
    }

    @GetMapping
    public List<DepartmentDTO> getAllDepartment() {
        return departmentService.getAllDepartments();
    }

    @GetMapping("/{id}")
    public DepartmentDTO getDepartment(@PathVariable Long id) {
        return departmentService.getDepartmentById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public DepartmentDTO createDepartment(@Valid @RequestBody DepartmentDTO department) {
        return departmentService.saveDepartment(department);
    }

    @PutMapping("/{id}")
    public DepartmentDTO updateDepartment(@PathVariable Long id, @Valid @RequestBody DepartmentDTO department) {
        department.setIdDepartment(id);
        return departmentService.saveDepartment(department);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteDepartment(@PathVariable Long id) {
        departmentService.deleteDepartment(id);
    }
}
