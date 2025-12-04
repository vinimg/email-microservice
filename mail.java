

@RestController
@RequestMapping("/api/email")
public class EmailController {

    @Autowired
    private EmailService emailService;

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
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Falha ao enviar: " + e.getMessage());
        }
    }
}

@Data
class EmailRequest {
    private String to;
    private String subject;
    private String body;
    private String pdfBase64;
    private String filename;
}

@Service
public class EmailService {

    @Autowired
    private JavaMailSender javaMailSender;

    public void sendEmailWithAttachment(String to, String subject, String body, String base64Pdf, String filename) throws MessagingException, IOException {
        MimeMessage message = javaMailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true);
        helper.setTo(to);
        helper.setSubject(subject);
        helper.setText(body, false);
        helper.setFrom("[email protected]");

        byte[] pdfBytes = Base64.getDecoder().decode(base64Pdf);
        DataSource dataSource = new ByteArrayDataSource(pdfBytes, "application/pdf");
        helper.addAttachment(filename, dataSource);

        javaMailSender.send(message);
    }
}
