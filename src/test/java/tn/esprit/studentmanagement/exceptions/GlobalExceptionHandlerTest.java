package tn.esprit.studentmanagement.exceptions;

import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

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
    void mapsValidationException() {
        MethodArgumentNotValidException ex = mock(MethodArgumentNotValidException.class);
        BindingResult bindingResult = mock(BindingResult.class);
        FieldError fieldError = new FieldError("objectName", "field", "defaultMessage");
        when(ex.getBindingResult()).thenReturn(bindingResult);
        when(bindingResult.getFieldErrors()).thenReturn(List.of(fieldError));

        ProblemDetail detail = handler.handleValidationException(ex);
        assertEquals(HttpStatus.BAD_REQUEST.value(), detail.getStatus());
        assertEquals("One or more request fields are invalid.", detail.getDetail());
        Map<String, String> errors = (Map<String, String>) detail.getProperties().get("errors");
        assertEquals("defaultMessage", errors.get("field"));
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
