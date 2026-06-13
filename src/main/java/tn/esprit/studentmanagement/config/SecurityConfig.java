package tn.esprit.studentmanagement.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

import java.util.ArrayList;
import java.util.List;

/**
 * Configuration de sécurité Spring Security.
 *
 * <p><b>CSRF</b>: Désactivé car il s'agit d'une API REST stateless utilisant
 * l'authentification HTTP Basic. Les tokens CSRF ne sont nécessaires que pour
 * les soumissions de formulaires avec sessions cookies.
 *
 * <p><b>Sécurité API</b>: Contrôlée par {@code api.security.enabled}
 * (variable d'environnement: {@code API_SECURITY_ENABLED}).
 * En production, définir à {@code true}. Tous les endpoints API nécessiteront
 * alors le rôle {@code API}.
 *
 * <p><b>Mots de passe par défaut</b>: Les valeurs par défaut ({@code changeme})
 * sont UNIQUEMENT pour le développement local.
 * En production, TOUJOURS définir les variables d'environnement suivantes :
 * <ul>
 *   <li>{@code ACTUATOR_PASSWORD}</li>
 *   <li>{@code API_PASSWORD}</li>
 *   <li>{@code MYSQL_PASSWORD}</li>
 * </ul>
 */
@Configuration
public class SecurityConfig {

    // ========================================================================
    // CHEMINS PUBLICS (non authentifiés)
    // ========================================================================
    private static final String[] PUBLIC_PATHS = {
        "/actuator/health",
        "/actuator/info",
        "/swagger-ui/**",
        "/v3/api-docs/**"
    };

    // ========================================================================
    // FILTRE DE SÉCURITÉ PRINCIPAL
    // ========================================================================
    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            @Value("${api.security.enabled:true}") boolean apiSecurityEnabled) throws Exception {

        // CSRF désactivé car API REST stateless (authentification via Basic Auth)
        // Pour une API REST, CSRF n'est pas nécessaire car les tokens ne sont pas
        // stockés dans des cookies. Une alternative plus sécurisée serait JWT ou OAuth2.
        http.csrf(AbstractHttpConfigurer::disable)
            .cors(Customizer.withDefaults())
            .authorizeHttpRequests(auth -> {
                // Endpoints publics (health, info, documentation)
                auth.requestMatchers(PUBLIC_PATHS).permitAll();

                // Endpoints Actuator nécessitent le rôle ACTUATOR
                auth.requestMatchers("/actuator/**").hasRole("ACTUATOR");

                // API endpoints
                if (apiSecurityEnabled) {
                    auth.anyRequest().hasRole("API");
                } else {
                    auth.anyRequest().permitAll();
                }
            })
            .httpBasic(Customizer.withDefaults());

        return http.build();
    }

    // ========================================================================
    // ENCODEUR DE MOTS DE PASSE
    // ========================================================================
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // ========================================================================
    // UTILISATEURS EN MÉMOIRE
    // ========================================================================
    @Bean
    public InMemoryUserDetailsManager userDetailsService(
            PasswordEncoder passwordEncoder,
            @Value("${actuator.username:actuator}") String actuatorUser,
            @Value("${actuator.password:changeme}") String actuatorPassword,
            @Value("${api.username:api-user}") String apiUser,
            @Value("${api.password:changeme}") String apiPassword,
            @Value("${api.security.enabled:true}") boolean apiSecurityEnabled) {

        List<UserDetails> users = new ArrayList<>();

        // Utilisateur ACTUATOR (obligatoire)
        users.add(User.builder()
                .username(actuatorUser)
                .password(passwordEncoder.encode(actuatorPassword))
                .roles("ACTUATOR")
                .build());

        // Utilisateur API (optionnel, activé uniquement si la sécurité API est requise)
        if (apiSecurityEnabled) {
            users.add(User.builder()
                    .username(apiUser)
                    .password(passwordEncoder.encode(apiPassword))
                    .roles("API")
                    .build());
        }

        return new InMemoryUserDetailsManager(users);
    }
}