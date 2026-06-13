#!/bin/bash
echo "🔧 Correction finale des tests + Flyway..."

./mvnw clean

# Correction des profils dans les tests (passer en "test")
sed -i 's/@ActiveProfiles("prod")/@ActiveProfiles("test")/g' src/test/java/tn/esprit/studentmanagement/*.java 2>/dev/null || true

# Vérification application-test.properties
if [ ! -f src/test/resources/application-test.properties ]; then
    cat > src/test/resources/application-test.properties << 'EOL'
spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.hibernate.ddl-auto=validate
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
EOL
fi

echo "🚀 Lancement des tests avec profil test..."
./mvnw clean test -Dspring.profiles.active=test --no-transfer-progress

echo "🎉 Tests terminés !"
echo "Pour lancer l'application en mode dev :"
echo "./mvnw spring-boot:run -Dspring.profiles.active=dev"
