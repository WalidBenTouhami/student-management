package tn.esprit.studentmanagement.controllers;

import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.mapper.StudentMapper;
import tn.esprit.studentmanagement.services.IStudentService;
import tn.esprit.studentmanagement.services.IDepartmentService;

import jakarta.validation.Valid;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/students")
@AllArgsConstructor
public class StudentController {
    IStudentService studentService;
    IDepartmentService departmentService;

    @GetMapping
    public org.springframework.data.domain.Page<StudentDTO> getAllStudents(@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "10") int size) {
        var studentsPage = studentService.getAllStudentsPaginated(page, size);
        var dtoList = studentsPage.getContent().stream().map(StudentMapper::toDto).collect(Collectors.toList());
        return new org.springframework.data.domain.PageImpl<>(dtoList, studentsPage.getPageable(), studentsPage.getTotalElements());
    }

    @GetMapping("/{id}")
    public StudentDTO getStudent(@PathVariable Long id) { return StudentMapper.toDto(studentService.getStudentById(id)); }

    @PostMapping
    public StudentDTO createStudent(@Valid @RequestBody StudentDTO studentDto) {
        Student s = StudentMapper.toEntity(studentDto);
        if (studentDto.getDepartmentId() != null) {
            Department dep = departmentService.getDepartmentById(studentDto.getDepartmentId());
            s.setDepartment(dep);
        }
        Student saved = studentService.saveStudent(s);
        return StudentMapper.toDto(saved);
    }

    @PutMapping
    public StudentDTO updateStudent(@Valid @RequestBody StudentDTO studentDto) {
        Student s = StudentMapper.toEntity(studentDto);
        if (studentDto.getDepartmentId() != null) {
            Department dep = departmentService.getDepartmentById(studentDto.getDepartmentId());
            s.setDepartment(dep);
        }
        Student saved = studentService.saveStudent(s);
        return StudentMapper.toDto(saved);
    }

    @DeleteMapping("/{id}")
    public void deleteStudent(@PathVariable Long id) { studentService.deleteStudent(id); }
}
