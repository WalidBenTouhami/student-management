#!/bin/bash
echo "🧹 Nettoyage complet du disque (urgence)..."

# 1. Nettoyage Maven (le plus gros consommateur)
echo "Nettoyage du cache Maven..."
rm -rf ~/.m2/repository/*
rm -rf ~/.m2/wrapper/*

# 2. Nettoyage du projet
echo "Nettoyage du projet student-management..."
cd ~/student-management
./mvnw clean
rm -rf target/

# 3. Nettoyage général du système
echo "Nettoyage du système Ubuntu..."
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove -y
sudo journalctl --vacuum-time=2weeks

# 4. Suppression des images Docker inutiles
echo "Nettoyage Docker..."
docker system prune -af --volumes

# 5. Vérification de l'espace disque
echo "=== ÉTAT DE L'ESPACE DISQUE ==="
df -h
echo ""
echo "Top 10 des plus gros dossiers :"
du -sh /* 2>/dev/null | sort -hr | head -10
du -sh /home/vagrant/* 2>/dev/null | sort -hr | head -5

echo "✅ Nettoyage terminé !"
