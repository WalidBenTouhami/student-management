package tn.esprit.studentmanagement.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.services.IStudentService;

import java.util.List;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/students")
public class StudentController {
    private IStudentService studentService;

    public StudentController(IStudentService studentService) {
        this.studentService = studentService;
    }

    @GetMapping
    public List<StudentDTO> getAllStudents() {
        return studentService.getAllStudents();
    }

    @GetMapping("/{id}")
    public StudentDTO getStudent(@PathVariable Long id) {
        return studentService.getStudentById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StudentDTO createStudent(@Valid @RequestBody StudentDTO studentDTO) {
        return studentService.saveStudent(studentDTO);
    }

    @PutMapping("/{id}")
    public StudentDTO updateStudent(@PathVariable Long id, @Valid @RequestBody StudentDTO studentDTO) {
        studentDTO.setIdStudent(id);
        return studentService.saveStudent(studentDTO);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteStudent(@PathVariable Long id) {
        studentService.deleteStudent(id);
    }
}
