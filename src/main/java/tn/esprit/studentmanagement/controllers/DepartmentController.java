package tn.esprit.studentmanagement.controllers;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.DepartmentDTO;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.mapper.DepartmentMapper;
import tn.esprit.studentmanagement.services.IDepartmentService;

@RestController
@RequestMapping("/departments")
@AllArgsConstructor
public class DepartmentController {
    private IDepartmentService departmentService;

    @GetMapping
    public org.springframework.data.domain.Page<DepartmentDTO> getAllDepartment(@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "10") int size) {
        var pageData = departmentService.getAllDepartmentsPaginated(page, size);
        var dtoList = pageData.getContent().stream().map(DepartmentMapper::toDto).toList();
        return new org.springframework.data.domain.PageImpl<>(dtoList, pageData.getPageable(), pageData.getTotalElements());
    }

    @GetMapping("/{id}")
    public DepartmentDTO getDepartment(@PathVariable Long id) { return DepartmentMapper.toDto(departmentService.getDepartmentById(id)); }

    @PostMapping
    public DepartmentDTO createDepartment(@Valid @RequestBody DepartmentDTO departmentDto) { 
        Department d = DepartmentMapper.toEntity(departmentDto);
        Department saved = departmentService.saveDepartment(d);
        return DepartmentMapper.toDto(saved);
    }

    @PutMapping
    public DepartmentDTO updateDepartment(@Valid @RequestBody DepartmentDTO departmentDto) {
        Department d = DepartmentMapper.toEntity(departmentDto);
        Department saved = departmentService.saveDepartment(d);
        return DepartmentMapper.toDto(saved);
    }

    @DeleteMapping("/{id}")
    public void deleteDepartment(@PathVariable Long id) { departmentService.deleteDepartment(id); }
}
