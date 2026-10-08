package com.ceylonheritage.backend.config;

import com.ceylonheritage.backend.security.JwtAuthFilter;
import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    public SecurityConfig(JwtAuthFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http
    ) throws Exception {

        http
                .cors(cors ->
                        cors.configurationSource(
                                corsConfigurationSource()
                        )
                )

                .csrf(csrf -> csrf.disable())

                .sessionManagement(session ->
                        session.sessionCreationPolicy(
                                SessionCreationPolicy.STATELESS
                        )
                )

                .authorizeHttpRequests(auth -> auth

                        // Public authentication endpoints.
                        .requestMatchers("/api/auth/**")
                        .permitAll()

                        // Submit a guide request without login.
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/guide-requests"
                        )
                        .permitAll()

                        // View approved guides without login.
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/guides/approved"
                        )
                        .permitAll()

                        // My Posts requires login.
                        // Keep this before public post rules.
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/posts/my"
                        )
                        .authenticated()

                        // Visitors can browse historical places.
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/places",
                                "/api/places/**"
                        )
                        .permitAll()

                        // Weather forecasts are public tourism information.
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/weather/**"
                        )
                        .permitAll()

                        // Visitors can view posts, like counts and comments.
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/posts",
                                "/api/posts/recent",
                                "/api/posts/{id}",
                                "/api/posts/{postId}/likes",
                                "/api/posts/{postId}/comments"
                        )
                        .permitAll()

                        // Visitors can view uploaded post photos.
                        .requestMatchers(
                                HttpMethod.GET,
                                "/uploads/community-posts/**"
                        )
                        .permitAll()

                        // Creating a post requires login.
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/posts"
                        )
                        .authenticated()

                        // Liking a post requires login.
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/posts/{postId}/like"
                        )
                        .authenticated()

                        // Removing a like requires login.
                        .requestMatchers(
                                HttpMethod.DELETE,
                                "/api/posts/{postId}/like"
                        )
                        .authenticated()

                        // Creating a comment requires login.
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/posts/{postId}/comments"
                        )
                        .authenticated()

                        // Deleting a comment requires login.
                        // The service also checks comment ownership.
                        .requestMatchers(
                                HttpMethod.DELETE,
                                "/api/posts/{postId}/comments/{commentId}"
                        )
                        .authenticated()

                        // All other requests require login.
                        .anyRequest()
                        .authenticated()
                )

                .formLogin(form -> form.disable())

                .httpBasic(basic -> basic.disable())

                .addFilterBefore(
                        jwtAuthFilter,
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }

    private UrlBasedCorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        configuration.setAllowedOriginPatterns(
                List.of("http://localhost:*", "http://127.0.0.1:*")
        );

        configuration.setAllowedMethods(
                List.of("GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS")
        );

        configuration.setAllowedHeaders(
                List.of(
                        "Content-Type",
                        "Accept",
                        "Authorization"
                )
        );

        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source =
                new UrlBasedCorsConfigurationSource();

        source.registerCorsConfiguration("/**", configuration);

        return source;
    }
}
