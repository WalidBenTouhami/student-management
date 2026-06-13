package tn.esprit.studentmanagement.controllers;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.DepartmentDTO;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.mapper.DepartmentMapper;
import tn.esprit.studentmanagement.services.IDepartmentService;


import org.springframework.data.domain.Page;

@RestController
@RequestMapping("/api/departments")
@RequiredArgsConstructor
public class DepartmentController {

    private final IDepartmentService departmentService;
    private final DepartmentMapper departmentMapper;

    @PostMapping
    public ResponseEntity<DepartmentDTO> create(@Valid @RequestBody DepartmentDTO dto) {
        Department entity = departmentMapper.toEntity(dto);
        Department saved = departmentService.saveDepartment(entity);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(departmentMapper.toDto(saved));
    }

    @GetMapping("/{id}")
    public ResponseEntity<DepartmentDTO> getById(@PathVariable Long id) {
        Department department = departmentService.getDepartmentById(id);
        return ResponseEntity.ok(departmentMapper.toDto(department));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DepartmentDTO> update(@PathVariable Long id, @Valid @RequestBody DepartmentDTO dto) {
        Department existing = departmentService.getDepartmentById(id);
        // Correction: l'ordre des paramètres doit correspondre à la définition du
        // mapper
        departmentMapper.updateEntity(dto, existing); // (source, target)
        Department updated = departmentService.saveDepartment(existing);
        return ResponseEntity.ok(departmentMapper.toDto(updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        departmentService.deleteDepartment(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<Page<DepartmentDTO>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Page<DepartmentDTO> departments = departmentService.getAllDepartmentsPaginated(page, size)
                .map(departmentMapper::toDto);
        return ResponseEntity.ok(departments);
    }
}