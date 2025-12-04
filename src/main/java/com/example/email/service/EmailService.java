package com.example.email.service;

import com.example.email.validation.PdfValidator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.InputStreamSource;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import javax.mail.MessagingException;
import javax.mail.internet.MimeMessage;
import javax.mail.util.ByteArrayDataSource;
import java.io.IOException;
import java.util.Base64;

@Service
public class EmailService {

    private final JavaMailSender javaMailSender;

    @Value("${spring.mail.from:sender@example.com}")
    private String from;

    @Autowired
    public EmailService(JavaMailSender javaMailSender) {
        this.javaMailSender = javaMailSender;
    }

    public void sendEmailWithAttachment(String to, String subject, String body, String base64Pdf, String filename) throws MessagingException, IOException {
        // Validar PDF (Base64 válido, magic bytes %PDF-, tamanho máximo)
        PdfValidator.validatePdfBase64(base64Pdf);

        MimeMessage message = javaMailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true);
        helper.setTo(to);
        helper.setSubject(subject);
        helper.setText(body, false);
        helper.setFrom(from);

        byte[] pdfBytes = Base64.getDecoder().decode(base64Pdf);
        ByteArrayDataSource dataSource = new ByteArrayDataSource(pdfBytes, "application/pdf");
        helper.addAttachment(filename, dataSource);

        javaMailSender.send(message);
    }
}
