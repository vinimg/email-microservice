package com.example.email.validation;

import java.util.Base64;

/**
 * Utilitário para validar anexos PDF.
 * Valida: Base64 válido, magic bytes %PDF-, tamanho máximo.
 */
public class PdfValidator {

    private static final byte[] PDF_MAGIC_BYTES = {0x25, 0x50, 0x44, 0x46}; // "%PDF"
    private static final long MAX_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB

    /**
     * Valida o PDF Base64.
     * @param base64Pdf string em Base64
     * @return true se válido; lança IllegalArgumentException caso contrário
     */
    public static void validatePdfBase64(String base64Pdf) {
        if (base64Pdf == null || base64Pdf.trim().isEmpty()) {
            throw new IllegalArgumentException("pdfBase64 não pode estar vazio");
        }

        // Validar Base64
        byte[] pdfBytes;
        try {
            pdfBytes = Base64.getDecoder().decode(base64Pdf);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("pdfBase64 inválido: não é um Base64 válido", e);
        }

        // Validar tamanho
        if (pdfBytes.length > MAX_SIZE_BYTES) {
            throw new IllegalArgumentException("Arquivo muito grande: " + pdfBytes.length + " bytes. Máximo permitido: " + MAX_SIZE_BYTES);
        }

        // Validar magic bytes (%PDF)
        if (pdfBytes.length < 4 || !isPdfMagicBytes(pdfBytes)) {
            throw new IllegalArgumentException("Arquivo não é um PDF válido: magic bytes %PDF não encontrados");
        }
    }

    private static boolean isPdfMagicBytes(byte[] data) {
        if (data.length < PDF_MAGIC_BYTES.length) {
            return false;
        }
        for (int i = 0; i < PDF_MAGIC_BYTES.length; i++) {
            if (data[i] != PDF_MAGIC_BYTES[i]) {
                return false;
            }
        }
        return true;
    }
}
