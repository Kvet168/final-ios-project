package com.wayfarer.user.web;

import com.wayfarer.security.CurrentUser;
import com.wayfarer.user.dto.UserDtos.DeleteAccountRequest;
import com.wayfarer.user.dto.UserDtos.UpdateProfileRequest;
import com.wayfarer.user.dto.UserDtos.UserDto;
import com.wayfarer.user.service.UserService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users/me")
@Tag(name = "Users")
public class UserController {
    private final UserService users;

    public UserController(UserService users) { this.users = users; }

    @GetMapping
    public UserDto me() { return users.me(CurrentUser.require().id()); }

    @PatchMapping
    public UserDto update(@Valid @RequestBody UpdateProfileRequest r) { return users.update(CurrentUser.require().id(), r); }

    /** Multipart field "file": PNG, JPEG or WebP up to 2 MB. */
    @PostMapping(value = "/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public UserDto setAvatar(@RequestParam("file") MultipartFile file) { return users.setAvatar(CurrentUser.require().id(), file); }

    @DeleteMapping("/avatar")
    public UserDto removeAvatar() { return users.removeAvatar(CurrentUser.require().id()); }

    @PostMapping("/delete")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@Valid @RequestBody DeleteAccountRequest r) { users.delete(CurrentUser.require().id(), r); }
}
