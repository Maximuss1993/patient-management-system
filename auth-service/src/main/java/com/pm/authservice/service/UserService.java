package src.main.java.com.pm.authservice.service;

import org.springframework.stereotype.Service;
import src.main.java.com.pm.authservice.model.User;
import src.main.java.com.pm.authservice.repository.UserRepository;

import java.util.Optional;

@Service
public class UserService {

  private final UserRepository userRepository;

  public UserService(UserRepository userRepository) {
    this.userRepository = userRepository;
  }

  public Optional<User> findByEmail(String email) {
    return userRepository.findByEmail(email);

  }
}
