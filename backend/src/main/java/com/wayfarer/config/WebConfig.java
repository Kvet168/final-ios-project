package com.wayfarer.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * The Admin and Partner dashboards are static single-page apps in src/main/resources/static (/admin, /partner, shared files in /dashboard).
 * They live on the same host as the API, so there is no CORS and nothing extra to deploy.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        for (String app : new String[] {"admin", "partner"}) {
            registry.addViewController("/" + app).setViewName("forward:/" + app + "/index.html");
            registry.addViewController("/" + app + "/").setViewName("forward:/" + app + "/index.html");
        }
    }
}
