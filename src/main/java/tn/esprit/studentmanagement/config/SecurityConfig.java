package tn.esprit.studentmanagement.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

import java.util.ArrayList;
import java.util.List;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            @Value("${app.security.api-enabled:false}") boolean apiSecurityEnabled) throws Exception {

        http
            .csrf(csrf -> csrf.disable())
            .cors(Customizer.withDefaults())
            .authorizeHttpRequests(auth -> {
                auth.requestMatchers("/actuator/**").hasRole("ACTUATOR");
                auth.requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll();
                if (apiSecurityEnabled) {
                    auth.anyRequest().hasRole("API");
                } else {
                    auth.anyRequest().permitAll();
                }
            })
            .httpBasic(Customizer.withDefaults());

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public InMemoryUserDetailsManager userDetailsService(
            PasswordEncoder passwordEncoder,
            @Value("${ACTUATOR_USER:actuator}") String actuatorUser,
            @Value("${ACTUATOR_PASSWORD:changeme}") String actuatorPassword,
            @Value("${app.security.api-enabled:false}") boolean apiSecurityEnabled,
            @Value("${API_USER:api}") String apiUser,
            @Value("${API_PASSWORD:changeme}") String apiPassword) {

        List<UserDetails> users = new ArrayList<>();

        users.add(User.withUsername(actuatorUser)
                .password(passwordEncoder.encode(actuatorPassword))
                .roles("ACTUATOR")
                .build());

        if (apiSecurityEnabled) {
            users.add(User.withUsername(apiUser)
                    .password(passwordEncoder.encode(apiPassword))
                    .roles("API")
                    .build());
        }

        return new InMemoryUserDetailsManager(users);
    }
}
