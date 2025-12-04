package com.example.email.controller;

import com.example.email.dto.EmailRequest;
import com.example.email.service.EmailService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/email")
public class EmailController {

    private final EmailService emailService;

    @Autowired
    public EmailController(EmailService emailService) {
        this.emailService = emailService;
    }

    @PostMapping("/send-pdf")
    public ResponseEntity<String> sendEmailWithPdf(@RequestBody EmailRequest request) {
        try {
            emailService.sendEmailWithAttachment(
                    request.getTo(),
                    request.getSubject(),
                    request.getBody(),
                    request.getPdfBase64(),
                    request.getFilename()
            );
            return ResponseEntity.ok("E-mail enviado com sucesso!");
        } catch (IllegalArgumentException e) {
            // Validação falhou (Base64 inválido, não é PDF, arquivo muito grande)
            return ResponseEntity.badRequest().body("Validação falhou: " + e.getMessage());
        } catch (Exception e) {
            // Erro ao enviar (SMTP, credenciais, rede, etc.)
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Falha ao enviar: " + e.getMessage());
        }
    }
}
