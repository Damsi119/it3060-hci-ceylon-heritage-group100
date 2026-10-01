package com.ceylonheritage.backend.security;

import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.repository.UserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    public CustomUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username)
            throws UsernameNotFoundException {

        User user = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() ->
                        new UsernameNotFoundException("User not found")
                );

        return user;
    }
}

