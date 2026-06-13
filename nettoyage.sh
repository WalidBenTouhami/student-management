#!/bin/bash
# Nettoyage progressif avec vérifications

echo "🧹 Nettoyage Docker (volumes non utilisés)"
docker volume prune -f

echo "📦 Nettoyage ciblé du cache Maven (uniquement votre projet)"
rm -rf ~/.m2/repository/tn/esprit/student-management
# Optionnel : forcer Maven à supprimer toutes les dépendances inutilisées (au prochain build)
# mvn dependency:purge-local-repository

echo "📊 Espace disque Docker"
docker system df

echo "📜 Nettoyage des logs système (dernier 100M)"
sudo journalctl --vacuum-size=100M

echo "🧹 Suppression des fichiers temporaires (sauf ceux utilisés par des processus actifs)"
sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || echo "Certains fichiers ne peuvent être supprimés maintenant"

echo "📁 Analyse de l'espace dans le workspace Jenkins"
cd /var/lib/jenkins/workspace/student-management 2>/dev/null && du -sh * | sort -rh | head -20 || echo "Répertoire Jenkins non trouvé"

echo "✅ Nettoyage terminé"
