package tn.esprit.studentmanagement.exceptions;

import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;

import static org.junit.jupiter.api.Assertions.assertEquals;

class GlobalExceptionHandlerTest {
    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void mapsNotFound() {
        ProblemDetail detail = handler.handleResourceNotFoundException(
                new ResourceNotFoundException("missing"), null);
        assertEquals(HttpStatus.NOT_FOUND.value(), detail.getStatus());
        assertEquals("missing", detail.getDetail());
    }

    @Test
    void mapsIllegalArgumentToConflict() {
        ProblemDetail detail = handler.handleIllegalArgumentException(
                new IllegalArgumentException("duplicate"));
        assertEquals(HttpStatus.CONFLICT.value(), detail.getStatus());
    }

    @Test
    void mapsDataIntegrityToConflict() {
        ProblemDetail detail = handler.handleDataIntegrityViolationException();
        assertEquals(HttpStatus.CONFLICT.value(), detail.getStatus());
    }

    @Test
    void hidesUnexpectedExceptionDetails() {
        ProblemDetail detail = handler.handleGlobalException(new RuntimeException("secret"), null);
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR.value(), detail.getStatus());
        assertEquals("An unexpected error occurred.", detail.getDetail());
    }
}
