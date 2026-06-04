package tn.esprit.studentmanagement.controllers;

import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
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
@CrossOrigin(origins = "http://localhost:4200")
@AllArgsConstructor
public class StudentController {
    IStudentService studentService;
    IDepartmentService departmentService;

    @GetMapping("/getAllStudents")
    public List<StudentDTO> getAllStudents() { return studentService.getAllStudents().stream().map(StudentMapper::toDto).collect(Collectors.toList()); }

    @GetMapping("/getStudent/{id}")
    public StudentDTO getStudent(@PathVariable Long id) { return StudentMapper.toDto(studentService.getStudentById(id)); }

    @PostMapping("/createStudent")
    public StudentDTO createStudent(@Valid @RequestBody StudentDTO studentDto) {
        Student s = StudentMapper.toEntity(studentDto);
        if (studentDto.departmentId != null) {
            Department dep = departmentService.getDepartmentById(studentDto.departmentId);
            s.setDepartment(dep);
        }
        Student saved = studentService.saveStudent(s);
        return StudentMapper.toDto(saved);
    }

    @PutMapping("/updateStudent")
    public StudentDTO updateStudent(@Valid @RequestBody StudentDTO studentDto) {
        Student s = StudentMapper.toEntity(studentDto);
        if (studentDto.departmentId != null) {
            Department dep = departmentService.getDepartmentById(studentDto.departmentId);
            s.setDepartment(dep);
        }
        Student saved = studentService.saveStudent(s);
        return StudentMapper.toDto(saved);
    }

    @DeleteMapping("/deleteStudent/{id}")
    public void deleteStudent(@PathVariable Long id) { studentService.deleteStudent(id); }
}
