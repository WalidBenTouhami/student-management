package tn.esprit.studentmanagement.services;

import tn.esprit.studentmanagement.dto.StudentDTO;

import java.util.List;

public interface IStudentService {
    public List<StudentDTO> getAllStudents();
    public StudentDTO getStudentById(Long id);
    public StudentDTO saveStudent(StudentDTO studentDTO);
    public void deleteStudent(Long id);
}
