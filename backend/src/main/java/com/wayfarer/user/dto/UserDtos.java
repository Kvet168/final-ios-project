package com.wayfarer.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

public final class UserDtos {
    private UserDtos() {}

    public record UserDto(UUID id, String email, String name, String phone, String role, String preferredCurrency, boolean isDemo, Instant createdAt, boolean mustChangePassword) {}

    public record UpdateProfileRequest(@Size(min = 2, max = 80) String name, @Size(max = 30) String phone, @Size(min = 3, max = 3) String preferredCurrency) {}

    public record DeleteAccountRequest(@NotBlank String password) {}

    public record RoleRequest(@NotBlank @Pattern(regexp = "customer|partner|staff|admin") String role) {}

    public record CreateUserRequest(
        @NotBlank @Size(min = 2, max = 80) String name,
        @NotBlank @Email @Size(max = 160) String email,
        @Size(max = 30) String phone,
        @NotBlank @Pattern(regexp = "customer|staff|admin") String role,
        @Size(min = 8, max = 100) String password
    ) {}
}
