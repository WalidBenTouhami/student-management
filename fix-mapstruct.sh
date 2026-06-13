#!/bin/bash
set -e

echo "🚀 Démarrage de la correction MapStruct + Build complet..."

# 1. Nettoyage complet
echo "🧹 Nettoyage du projet..."
./mvnw clean
rm -rf target/
rm -rf ~/.m2/repository/tn/esprit/studentmanagement/

# 2. Vérification et correction du pom.xml
echo "🔧 Vérification configuration Maven MapStruct..."
if ! grep -q "mapstruct-processor" pom.xml; then
    echo "⚠️  Ajout de la configuration MapStruct dans pom.xml..."
    # Ce bloc sera ajouté si absent
    sed -i '/<plugins>/a \
        <plugin>\
            <groupId>org.apache.maven.plugins</groupId>\
            <artifactId>maven-compiler-plugin</artifactId>\
            <version>3.13.0</version>\
            <configuration>\
                <source>21</source>\
                <target>21</target>\
                <annotationProcessorPaths>\
                    <path>\
                        <groupId>org.mapstruct</groupId>\
                        <artifactId>mapstruct-processor</artifactId>\
                        <version>1.6.3</version>\
                    </path>\
                    <path>\
                        <groupId>org.projectlombok</groupId>\
                        <artifactId>lombok</artifactId>\
                        <version>1.18.38</version>\
                    </path>\
                </annotationProcessorPaths>\
                <compilerArgs>\
                    <arg>-Amapstruct.defaultComponentModel=spring</arg>\
                </compilerArgs>\
            </configuration>\
        </plugin>' pom.xml
fi

# 3. Compilation avec génération des mappers
echo "🔨 Compilation + Génération MapStruct..."
./mvnw clean compile -U --no-transfer-progress

# 4. Vérification des fichiers générés
echo "✅ Vérification des implémentations MapStruct..."
if [ -d "target/generated-sources/annotations/tn/esprit/studentmanagement/mapper" ]; then
    echo "✅ Succès ! Fichiers générés :"
    ls -l target/generated-sources/annotations/tn/esprit/studentmanagement/mapper/
else
    echo "❌ Échec : Dossier generated-sources non trouvé"
    exit 1
fi

# 5. Tests complets
echo "🧪 Lancement des tests complets..."
./mvnw verify --no-transfer-progress

echo "🎉 Correction terminée avec succès !"
echo "Vous pouvez maintenant lancer l'application : ./mvnw spring-boot:run"
