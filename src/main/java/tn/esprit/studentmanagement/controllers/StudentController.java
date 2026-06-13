package tn.esprit.studentmanagement.controllers;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.mapper.StudentMapper;
import tn.esprit.studentmanagement.services.IStudentService;

import java.util.List;

@RestController
@RequestMapping("/api/students")
@RequiredArgsConstructor
public class StudentController {

    private final IStudentService studentService;
    private final StudentMapper studentMapper;

    @PostMapping
    public ResponseEntity<StudentDTO> create(@Valid @RequestBody StudentDTO dto) {
        Student entity = studentMapper.toEntity(dto);
        Student saved = studentService.saveStudent(entity);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(studentMapper.toDto(saved));
    }

    @GetMapping("/{id}")
    public ResponseEntity<StudentDTO> getById(@PathVariable Long id) {
        Student student = studentService.getStudentById(id);
        return ResponseEntity.ok(studentMapper.toDto(student));
    }

    @PutMapping("/{id}")
    public ResponseEntity<StudentDTO> update(@PathVariable Long id, @Valid @RequestBody StudentDTO dto) {
        Student existing = studentService.getStudentById(id);
        studentMapper.updateEntity(dto, existing);
        Student updated = studentService.saveStudent(existing);
        return ResponseEntity.ok(studentMapper.toDto(updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        studentService.deleteStudent(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<List<StudentDTO>> getAll() {
        List<StudentDTO> students = studentService.getAllStudents().stream()
                .map(studentMapper::toDto)
                .toList();
        return ResponseEntity.ok(students);
    }

    @GetMapping("/department/{departmentId}")
    public ResponseEntity<List<StudentDTO>> getByDepartment(@PathVariable Long departmentId) {
        List<StudentDTO> students = studentService.getStudentsByDepartment(departmentId).stream()
                .map(studentMapper::toDto)
                .toList();
        return ResponseEntity.ok(students);
    }
}