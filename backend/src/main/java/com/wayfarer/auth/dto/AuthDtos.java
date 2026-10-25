package com.wayfarer.auth.dto;

import com.wayfarer.user.dto.UserDtos.UserDto;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class AuthDtos {
    private AuthDtos() {}

    public static final String PASSWORD_RULE = "^(?=.*[A-Za-z])(?=.*\\d).{10,128}$";
    public static final String PASSWORD_MSG = "Use 10-128 characters with letters and at least one number";

    public record RegisterRequest(
        @NotBlank @Email @Size(max = 160) String email,
        @NotBlank @Pattern(regexp = PASSWORD_RULE, message = PASSWORD_MSG) String password,
        @NotBlank @Size(min = 2, max = 80) String name,
        @Size(max = 30) String phone) {}

    public record LoginRequest(@NotBlank @Email String email, @NotBlank @Size(max = 128) String password) {}

    public record GoogleLoginRequest(@NotBlank @Size(max = 4000) String idToken) {}

    public record RefreshRequest(@NotBlank @Size(min = 20, max = 200) String refreshToken) {}

    public record ForgotPasswordRequest(@NotBlank @Email String email) {}

    public record ResetPasswordRequest(@NotBlank @Size(min = 10, max = 100) String token,
                                       @NotBlank @Pattern(regexp = PASSWORD_RULE, message = PASSWORD_MSG) String password) {}

    public record ChangePasswordRequest(@NotBlank @Size(max = 128) String currentPassword,
                                        @NotBlank @Pattern(regexp = PASSWORD_RULE, message = PASSWORD_MSG) String newPassword) {}

    public record TokenResponse(String accessToken, String refreshToken, long expiresIn, String tokenType) {}

    public record AuthResponse(UserDto user, String accessToken, String refreshToken, long expiresIn, String tokenType) {}
}
