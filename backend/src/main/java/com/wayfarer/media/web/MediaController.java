package com.wayfarer.media.web;

import com.wayfarer.media.service.MediaService;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.Duration;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/media")
@Tag(name = "Media")
public class MediaController {
    private final MediaService media;

    public MediaController(MediaService media) { this.media = media; }

    /** Partners, staff and admins only (SecurityConfig). Multipart field name: file. */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> upload(@RequestParam("file") MultipartFile file) { return media.store(CurrentUser.require().id(), file); }

    /** Public: images appear in the catalogue. Ids are unguessable UUIDs; content never changes, so it is cached hard. */
    @GetMapping("/{id}")
    @SecurityRequirements
    public ResponseEntity<byte[]> get(@PathVariable UUID id) {
        Map<String, Object> m = media.load(id);
        return ResponseEntity.ok().contentType(MediaType.parseMediaType((String) m.get("content_type")))
            .cacheControl(CacheControl.maxAge(Duration.ofDays(30)).cachePublic().immutable()).body((byte[]) m.get("data"));
    }
}
