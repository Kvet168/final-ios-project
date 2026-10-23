package com.wayfarer.wishlist.web;

import com.wayfarer.security.CurrentUser;
import com.wayfarer.wishlist.service.WishlistService;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
@Tag(name = "Wishlist")
public class WishlistController {
    private final WishlistService wishlist;

    public WishlistController(WishlistService wishlist) { this.wishlist = wishlist; }

    @GetMapping("/wishlist")
    public Map<String, Object> list() { return wishlist.list(CurrentUser.require().id()); }

    @PutMapping("/wishlist/{kind}/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void add(@PathVariable String kind, @PathVariable UUID id) { wishlist.add(CurrentUser.require().id(), kind, id); }

    @DeleteMapping("/wishlist/{kind}/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@PathVariable String kind, @PathVariable UUID id) { wishlist.remove(CurrentUser.require().id(), kind, id); }

    @GetMapping("/search-history")
    public Map<String, Object> history() { return wishlist.searchHistory(CurrentUser.require().id()); }
}
