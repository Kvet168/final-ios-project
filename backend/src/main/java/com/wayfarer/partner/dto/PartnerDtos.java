package com.wayfarer.partner.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public final class PartnerDtos {
    private PartnerDtos() {}

    /** Administrator creates a partner organisation together with its owner login. */
    public record CreatePartnerRequest(@NotBlank @Size(min = 2, max = 100) String businessName, @NotBlank @Size(min = 2, max = 80) String ownerName,
                                       @NotBlank @Email @Size(max = 160) String email, @Size(max = 30) String phone,
                                       @Size(min = 8, max = 100) String password) {}

    /** Partner's own organisation and QR payment settings. qrMediaId must be an image the partner uploaded. */
    public record ProfileRequest(@Size(min = 2, max = 100) String name, @Size(max = 30) String contactPhone, UUID qrMediaId,
                                 @Size(max = 100) String accountName, @Size(max = 100) String bank, @Size(max = 300) String note) {}

    public record ImageRequest(@NotBlank @Size(max = 500) String url, @Size(max = 200) String caption) {}

    public record DecisionRequest(@Size(max = 200) String reason) {}
}
