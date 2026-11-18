package com.wayfarer.media.service;

import com.wayfarer.common.ApiException;
import com.wayfarer.media.repository.MediaRepository;
import java.io.IOException;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

/**
 * Image uploads (PNG, JPEG, WebP up to 2 MB). The type is decided from the file's own bytes, never from the name or the declared
 * content type, and SVG is refused, so an uploaded file cannot carry script.
 */
@Service
public class MediaService {
    public static final long MAX_BYTES = 2L * 1024 * 1024;
    private static final String PREFIX = "/api/media/";
    private static final Pattern MEDIA_URL = Pattern.compile("^/api/media/([0-9a-f-]{36})$");

    private final MediaRepository media;

    public MediaService(MediaRepository media) { this.media = media; }

    public static String urlFor(UUID id) { return PREFIX + id; }

    static String sniff(byte[] b) {
        if (b.length >= 8 && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') return "image/png";
        if (b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) return "image/jpeg";
        if (b.length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F' && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') return "image/webp";
        return null;
    }

    public Map<String, Object> store(UUID ownerId, MultipartFile file) {
        if (file == null || file.isEmpty()) throw ApiException.unprocessable("VALIDATION_ERROR", "Choose an image file");
        if (file.getSize() > MAX_BYTES) throw new ApiException(org.springframework.http.HttpStatus.PAYLOAD_TOO_LARGE, "TOO_LARGE", "Images can be at most 2 MB");
        byte[] data;
        try {
            data = file.getBytes();
        } catch (IOException e) {
            throw ApiException.unprocessable("VALIDATION_ERROR", "The file could not be read");
        }
        String type = sniff(data);
        if (type == null) throw ApiException.unprocessable("UNSUPPORTED_IMAGE", "Only PNG, JPEG or WebP images are accepted");
        UUID id = media.insert(ownerId, type, data);
        return Map.of("id", id, "url", urlFor(id), "contentType", type, "size", data.length);
    }

    /** Removes an image the owner uploaded, given its "/api/media/{id}" URL; anything else is ignored. */
    public void deleteByUrl(UUID ownerId, String url) {
        if (url == null) return;
        Matcher m = MEDIA_URL.matcher(url);
        if (m.matches()) media.deleteOwned(UUID.fromString(m.group(1)), ownerId);
    }

    public Map<String, Object> load(UUID id) { return media.find(id).orElseThrow(() -> ApiException.notFound("Image")); }

    /** Accepts only an image the caller uploaded (as "/api/media/{id}") or an https URL; everything else is rejected. */
    public String requireSafeImageUrl(UUID ownerId, String url) {
        if (url == null || url.isBlank()) return null;
        Matcher m = MEDIA_URL.matcher(url.trim());
        if (m.matches()) {
            if (!media.ownedBy(UUID.fromString(m.group(1)), ownerId)) throw ApiException.unprocessable("VALIDATION_ERROR", "That image was not uploaded by you");
            return url.trim();
        }
        if (url.trim().startsWith("https://") && url.length() <= 500) return url.trim();
        throw ApiException.unprocessable("VALIDATION_ERROR", "Use an uploaded image or an https:// image URL");
    }

    public void requireOwnedMedia(UUID ownerId, UUID mediaId) {
        if (mediaId != null && !media.ownedBy(mediaId, ownerId)) throw ApiException.unprocessable("VALIDATION_ERROR", "That image was not uploaded by you");
    }
}
