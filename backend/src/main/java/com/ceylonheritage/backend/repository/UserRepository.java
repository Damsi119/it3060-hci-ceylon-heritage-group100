package com.ceylonheritage.backend.repository;

import com.ceylonheritage.backend.entities.User;
import com.ceylonheritage.backend.enums.Role;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmailIgnoreCaseAndDeletedFalse(String email);

    Optional<User> findByUsernameIgnoreCaseAndDeletedFalse(String username);

    Optional<User> findByPhoneAndDeletedFalse(String phone);

    Optional<User> findByIdAndDeletedFalse(Long id);

    boolean existsByEmailIgnoreCaseAndDeletedFalse(String email);

    boolean existsByUsernameIgnoreCaseAndDeletedFalse(String username);

    boolean existsByPhoneAndDeletedFalse(String phone);

    boolean existsByRoleAndDeletedFalse(Role role);

    List<User> findByDeletedFalse();

    List<User> findByRoleAndDeletedFalse(Role role);
}
