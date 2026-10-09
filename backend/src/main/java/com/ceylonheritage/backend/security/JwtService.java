package com.ceylonheritage.backend.security;

import com.ceylonheritage.backend.entities.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;

@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.access-token-expiration}")
    private long accessTokenExpiration;

    @Value("${jwt.refresh-token-expiration}")
    private long refreshTokenExpiration;


    public String generateAccessToken(User user) {

        Date now = new Date();
        Date expiry = new Date(now.getTime() + accessTokenExpiration);

        return Jwts.builder()
                .subject(user.getUsername())
                .claim("role", user.getRole().name())
                .claim("type", "ACCESS")
                .issuedAt(now)
                .expiration(expiry)
                .signWith(getSigningKey())
                .compact();
    }


    public String generateRefreshToken(User user) {

        Date now = new Date();
        Date expiry = new Date(now.getTime() + refreshTokenExpiration);

        return Jwts.builder()
                .subject(user.getUsername())
                .claim("type", "REFRESH")
                .issuedAt(now)
                .expiration(expiry)
                .signWith(getSigningKey())
                .compact();
    }


    public String extractUsername(String token) {
        return extractClaims(token).getSubject();
    }


    public String extractRole(String token) {
        return extractClaims(token).get("role", String.class);
    }


    public String extractTokenType(String token) {
        return extractClaims(token).get("type", String.class);
    }


    public boolean isAccessTokenValid(String token, User user) {

        try {
            String username = extractUsername(token);
            String type = extractTokenType(token);

            return username.equalsIgnoreCase(user.getUsername())
                    && "ACCESS".equals(type)
                    && !isTokenExpired(token)
                    && user.isEnabled();

        } catch (JwtException | IllegalArgumentException exception) {
            return false;
        }
    }


    public boolean isRefreshTokenValid(String token, User user) {

        try {
            String username = extractUsername(token);
            String type = extractTokenType(token);

            return username.equalsIgnoreCase(user.getUsername())
                    && "REFRESH".equals(type)
                    && !isTokenExpired(token)
                    && user.isEnabled();

        } catch (JwtException | IllegalArgumentException exception) {
            return false;
        }
    }


    public boolean isTokenExpired(String token) {

        Date expiration = extractClaims(token).getExpiration();

        return expiration.before(new Date());
    }


    private Claims extractClaims(String token) {

        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }


    private SecretKey getSigningKey() {

        byte[] keyBytes = Decoders.BASE64.decode(secret);

        return Keys.hmacShaKeyFor(keyBytes);
    }
}

