Vagrant.configure("2") do |config|
  # Image de base Ubuntu 22.04
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.box_download_options = {"ssl-no-revoke" => true}

  # ========== RÉSEAU ==========
  # CORRECTION CRITIQUE : Ne jamais utiliser 10.0.2.x pour un réseau privé. 
  # C'est la plage d'adresses réservée au NAT de VirtualBox et causera des conflits de routage.
  config.vm.network :private_network, ip: "192.168.56.10"

  # ========== REDIRECTION DES PORTS ==========
  # Jenkins (dans la VM sur 8080 → hôte 9090)
  # CORRECTION : Le port par défaut de Jenkins est 8080 et non 8090.
  config.vm.network "forwarded_port", guest: 8080, host: 9090
  
  # SonarQube (VM 9000 → hôte 9000)
  config.vm.network "forwarded_port", guest: 9000, host: 9000
  
  # Application Student Management (Spring Boot)
  config.vm.network "forwarded_port", guest: 8089, host: 8089
  
  # Kubernetes NodePort (Optionnel : si Minikube tourne dans la VM)
  config.vm.network "forwarded_port", guest: 30089, host: 30089

  # ========== PARTAGE DE DOSSIERS ==========
  config.vm.synced_folder __dir__, "/home/vagrant/student-management"
  # Note: 'optional: true' évite que Vagrant échoue au démarrage si le dossier n'existe pas encore sur l'hôte
  # config.vm.synced_folder File.expand_path("../DevOpsLab", __dir__), "/home/vagrant/devopslab", optional: true

  # ========== RESSOURCES VIRTUALBOX ==========
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "10240"   # 10 Go RAM
    vb.cpus = 4
    # OPTIMISATIONS : Amélioration des performances E/S et DNS
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  # ========== PROVISIONING ==========
  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    
    echo "🔄 Mise à jour des paquets..."
    sudo apt-get update -y
    
    echo "🐳 Installation de Docker..."
    if ! command -v docker &> /dev/null; then
      curl -fsSL https://get.docker.com -o get-docker.sh
      sudo sh get-docker.sh
      sudo usermod -aG docker vagrant
    fi

    echo "🐳 Installation de Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
      sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
    fi

    echo "☕ Installation de Java 21 (JDK) et utilitaires..."
    sudo apt-get install -y openjdk-21-jdk openjdk-21-jre maven git unzip apt-transport-https ca-certificates gnupg lsb-release

    echo "🏗️ Installation de Jenkins..."
    if ! command -v jenkins &> /dev/null; then
      sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
        https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
      echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
        https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
        /etc/apt/sources.list.d/jenkins.list > /dev/null
      sudo apt-get update -y
      sudo apt-get install -y jenkins
      sudo usermod -aG docker jenkins
      sudo systemctl start jenkins
      sudo systemctl enable jenkins
    fi

    echo "🛡️ Installation de Trivy..."
    if ! command -v trivy &> /dev/null; then
      wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
      echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
      sudo apt-get update -y
      sudo apt-get install -y trivy
    fi

    echo "☸️ Installation de Kubectl..."
    if ! command -v kubectl &> /dev/null; then
      sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
      sudo apt-get update -y
      sudo apt-get install -y kubectl
    fi

    echo "⛵ Installation de Helm..."
    if ! command -v helm &> /dev/null; then
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

    echo "🧪 Configuration des paramètres système pour SonarQube..."
    # Elasticsearch (embarqué dans SonarQube) nécessite ces limites de mémoire virtuelle
    if ! grep -q "vm.max_map_count" /etc/sysctl.conf; then
      echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
      echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.conf
      sudo sysctl -p
    fi

    echo "📊 Lancement de SonarQube via Docker..."
    if ! sudo docker ps -a --format '{{.Names}}' | grep -Eq "^sonarqube$"; then
      sudo docker run -d --name sonarqube \
        -p 9000:9000 \
        --restart always \
        sonarqube:lts-community
    fi

    echo "🚀 Installation de Minikube..."
    if ! command -v minikube &> /dev/null; then
      curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
      sudo install minikube-linux-amd64 /usr/local/bin/minikube
    fi

    echo "☸️ Démarrage de Minikube..."
    # Démarrage sous l'utilisateur vagrant avec sg docker pour contourner le délai de mise à jour des groupes
    if ! sudo -u vagrant sg docker -c "minikube status" &> /dev/null; then
      sudo -u vagrant sg docker -c "minikube start --driver=docker --cpus=4 --memory=4096 --disk-size=20g"
      sudo -u vagrant sg docker -c "minikube addons enable metrics-server"
    fi

    echo "🔑 Configuration des permissions Kubernetes & Docker pour Jenkins..."
    # Permet au service Jenkins d'accéder au contexte local de Minikube et d'éviter les soucis de droits
    sudo usermod -aG vagrant jenkins
    sudo chmod g+rx /home/vagrant
    sudo chmod -R g+r /home/vagrant/.kube || true
    sudo chmod -R g+rx /home/vagrant/.minikube || true

    # Redémarrage de Jenkins pour valider ses nouveaux groupes (docker, vagrant)
    sudo systemctl restart jenkins

    echo "🎉 Provisioning terminé !"
    echo "🔗 Accès Jenkins : http://localhost:9090 (ou http://192.168.56.10:8080)"
    echo "🔗 Accès SonarQube : http://localhost:9000 (ou http://192.168.56.10:9000)"
  SHELL
end
