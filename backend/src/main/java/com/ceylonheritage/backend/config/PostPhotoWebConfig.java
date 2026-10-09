package com.ceylonheritage.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;

@Configuration
public class PostPhotoWebConfig implements WebMvcConfigurer {

    private final String postResourceLocation;
    private final String profileResourceLocation;

    public PostPhotoWebConfig(
            @Value("${app.upload.post-directory:uploads/community-posts}")
            String postDirectory,

            @Value("${app.upload.profile-directory:uploads/profile-images}")
            String profileDirectory
    ) {
        this.postResourceLocation = resourceLocation(postDirectory);
        this.profileResourceLocation = resourceLocation(profileDirectory);
    }

    private String resourceLocation(String directory) {
        String location = Path.of(directory)
                .toAbsolutePath()
                .normalize()
                .toUri()
                .toString();

        return location.endsWith("/")
                ? location
                : location + "/";
    }

    @Override
    public void addResourceHandlers(
            ResourceHandlerRegistry registry
    ) {
        registry
                .addResourceHandler("/uploads/community-posts/**")
                .addResourceLocations(postResourceLocation);

        registry
                .addResourceHandler("/uploads/profile-images/**")
                .addResourceLocations(profileResourceLocation);
    }
}
