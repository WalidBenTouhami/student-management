#!/bin/bash
# scripts/install-k8s.sh
# Installation de Kubernetes (Minikube) et Kubectl

set -e

echo "📦 Installation de kubectl..."
curl -LO "https://dl.k8s.io/release/v1.33.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "📦 Installation de Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube

echo "🚀 Démarrage de Minikube avec le driver Docker..."
# Important: On le lance en tant que vagrant pour ne pas casser les permissions si lancé avec sudo
sudo -u vagrant minikube start --driver=docker --cpus=2 --memory=4096

echo "🔌 Activation de l'Ingress Controller Minikube..."
sudo -u vagrant minikube addons enable ingress

echo "📦 Installation de Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

echo "⚙️  Configuration des permissions pour Jenkins..."
# Jenkins doit pouvoir exécuter kubectl et minikube
sudo usermod -aG docker jenkins || true
sudo mkdir -p /var/lib/jenkins/.kube
sudo mkdir -p /var/lib/jenkins/.minikube
sudo cp -R /home/vagrant/.kube/* /var/lib/jenkins/.kube/ 2>/dev/null || true
sudo cp -R /home/vagrant/.minikube/* /var/lib/jenkins/.minikube/ 2>/dev/null || true

# Remplacer les chemins /home/vagrant par /var/lib/jenkins dans le fichier config pour Jenkins
if [ -f /var/lib/jenkins/.kube/config ]; then
    sudo sed -i 's|/home/vagrant|/var/lib/jenkins|g' /var/lib/jenkins/.kube/config
fi

sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube /var/lib/jenkins/.minikube

echo "✅ Minikube et Kubectl sont installés et configurés pour vagrant et jenkins."
kubectl get nodes
