package com.ceylonheritage.backend.exception;

import com.ceylonheritage.backend.Dtos.UserDto;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserException.class)
    public ResponseEntity<UserDto.MessageResponse> handleUserException(
            UserException exception
    ) {

        return ResponseEntity
                .badRequest()
                .body(new UserDto.MessageResponse(
                        false,
                        exception.getMessage()
                ));
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<UserDto.MessageResponse> handleAuthenticationException(
            AuthenticationException exception
    ) {

        return ResponseEntity
                .status(HttpStatus.UNAUTHORIZED)
                .body(new UserDto.MessageResponse(
                        false,
                        "Authentication required"
                ));
    }


    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<UserDto.MessageResponse> handleAccessDeniedException(
            AccessDeniedException exception
    ) {

        return ResponseEntity
                .status(HttpStatus.FORBIDDEN)
                .body(new UserDto.MessageResponse(
                        false,
                        "Access denied"
                ));
    }


    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<UserDto.MessageResponse> handleValidationException(
            MethodArgumentNotValidException exception
    ) {

        String message = exception
                .getBindingResult()
                .getFieldErrors()
                .stream()
                .findFirst()
                .map(error -> error.getDefaultMessage())
                .orElse("Invalid request");

        return ResponseEntity
                .badRequest()
                .body(new UserDto.MessageResponse(
                        false,
                        message
                ));
    }


    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<UserDto.MessageResponse> handleMissingRequestParameter(
            MissingServletRequestParameterException exception
    ) {

        return ResponseEntity
                .badRequest()
                .body(new UserDto.MessageResponse(
                        false,
                        "Missing request parameter: " + exception.getParameterName()
                ));
    }


    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<UserDto.MessageResponse> handleTypeMismatchException(
            MethodArgumentTypeMismatchException exception
    ) {

        return ResponseEntity
                .badRequest()
                .body(new UserDto.MessageResponse(
                        false,
                        "Invalid request parameter"
                ));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<UserDto.MessageResponse> handleResponseStatusException(
            ResponseStatusException exception
    ) {
        String message = exception.getReason() == null ? "Request failed" : exception.getReason();
        return ResponseEntity.status(exception.getStatusCode())
                .body(new UserDto.MessageResponse(false, message));
    }


    @ExceptionHandler(Exception.class)
    public ResponseEntity<UserDto.MessageResponse> handleException(
            Exception exception
    ) {

        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new UserDto.MessageResponse(
                        false,
                        "Something went wrong"
                ));
    }
}

