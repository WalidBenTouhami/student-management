# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # ============================================================
  # 1. CONFIGURATION DE BASE
  # ============================================================
  config.vm.box = "bento/ubuntu-26.04"
  config.vm.box_version = "202606.01.0"
  config.vm.box_download_options = {"ssl-no-revoke" => true}
  config.vm.hostname = "devops-vm"
  config.vm.boot_timeout = 600

  # ============================================================
  # 2. RÉSEAU
  # ============================================================
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.network "forwarded_port", guest: 8080, host: 8088, auto_correct: true   # Jenkins
  config.vm.network "forwarded_port", guest: 9000, host: 9000, auto_correct: true   # SonarQube
  config.vm.network "forwarded_port", guest: 3000, host: 3000, auto_correct: true   # Grafana
  config.vm.network "forwarded_port", guest: 9090, host: 9090, auto_correct: true   # Prometheus
  config.vm.network "forwarded_port", guest: 3306, host: 3306, auto_correct: true   # MySQL
  config.vm.network "forwarded_port", guest: 8089, host: 8089, auto_correct: true   # Spring Boot
  config.vm.network "forwarded_port", guest: 5005, host: 5005, auto_correct: true   # Debug
  config.vm.network "forwarded_port", guest: 22, host: 2222, auto_correct: true     # SSH

  # ============================================================
  # 3. PROVIDER VIRTUALBOX
  # ============================================================
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 8192
    vb.cpus = 4
    vb.name = "DevOps-Professional-VM"

    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    vb.customize ["modifyvm", :id, "--vram", "128"]
    vb.customize ["modifyvm", :id, "--paravirtprovider", "hyperv"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
  end

  # ============================================================
  # 4. SYNC DES DOSSIERS (pour IntelliJ)
  # ============================================================
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  config.vm.synced_folder "./projects", "/home/vagrant/projects", create: true
  config.vm.synced_folder "./.idea", "/home/vagrant/.idea", create: true, owner: "vagrant", group: "vagrant"

  # ============================================================
  # 5. PROVISIONNEMENT COMPLET PROFESSIONNEL
  # ============================================================
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    #!/bin/bash

    # ==========================================================
    # 5.1 VARIABLES GLOBALES
    # ==========================================================

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
    MYSQL_DATABASE="studentdb"
    MYSQL_USER="spring"
    MYSQL_PASSWORD=$(openssl rand -base64 12)

    LOG_FILE="/home/vagrant/provision.log"
    touch $LOG_FILE

    # ==========================================================
    # 5.2 FONCTIONS DE LOGGING
    # ==========================================================

    log_info() {
      echo -e "${GREEN}[INFO]${NC} $1" | tee -a $LOG_FILE
    }

    log_warn() {
      echo -e "${YELLOW}[WARN]${NC} $1" | tee -a $LOG_FILE
    }

    log_error() {
      echo -e "${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE
    }

    log_success() {
      echo -e "${PURPLE}[SUCCESS]${NC} $1" | tee -a $LOG_FILE
    }

    log_section() {
      echo "" | tee -a $LOG_FILE
      echo -e "${CYAN}============================================================${NC}" | tee -a $LOG_FILE
      echo -e "${CYAN}  $1${NC}" | tee -a $LOG_FILE
      echo -e "${CYAN}============================================================${NC}" | tee -a $LOG_FILE
      echo "" | tee -a $LOG_FILE
    }

    # ==========================================================
    # 5.3 FONCTIONS DE VÉRIFICATION
    # ==========================================================

    check_ruby_environment() {
      log_section "🔴 VÉRIFICATION DE L'ENVIRONNEMENT RUBY POUR INTELLIJ"

      # Vérification Ruby
      log_info "Vérification de Ruby..."
      if command -v ruby &> /dev/null; then
        RUBY_VERSION=$(ruby --version | cut -d' ' -f2)
        log_success "✅ Ruby version $RUBY_VERSION installé"
      else
        log_warn "⚠️ Ruby non trouvé, installation..."
        sudo apt-get install -y ruby-full ruby-dev ruby-bundler
      fi

      # Vérification Rails (optionnel pour les projets)
      if command -v rails &> /dev/null; then
        RAILS_VERSION=$(rails --version | cut -d' ' -f2)
        log_success "✅ Rails version $RAILS_VERSION installé"
      else
        log_warn "⚠️ Rails non installé (optionnel)"
      fi

      # Vérification Gem
      if command -v gem &> /dev/null; then
        GEM_VERSION=$(gem --version)
        log_success "✅ RubyGems version $GEM_VERSION installé"
      else
        log_error "❌ RubyGems non trouvé"
      fi

      # Installation des gems nécessaires pour IntelliJ
      log_info "📦 Installation des gems pour IntelliJ..."
      gem install bundler rake json 2>&1 | tee -a $LOG_FILE

      # Vérification des chemins Ruby
      log_info "📂 Chemins Ruby :"
      gem env | tee -a $LOG_FILE

      # Configuration .gemrc pour IntelliJ
      cat > ~/.gemrc << EOF
---
gem: --no-document
:verbose: true
:update_sources: true
:sources:
- https://rubygems.org/
:backtrace: false
:bulk_threshold: 1000
EOF

      # Variables d'environnement pour IntelliJ
      echo 'export RUBY_HOME=/usr/bin/ruby' >> ~/.bashrc
      echo 'export GEM_HOME=$(ruby -e "puts Gem.user_dir")' >> ~/.bashrc
      echo 'export PATH=$GEM_HOME/bin:$PATH' >> ~/.bashrc
      source ~/.bashrc

      # Vérification de la compatibilité
      log_info "🔍 Vérification de la compatibilité Ruby/IntelliJ..."
      echo "   ✅ IntelliJ IDEA 2024+ supporte Ruby 2.5+"
      echo "   ✅ RubyMine 2024+ supporte Ruby 2.5+"

      # Création du fichier .ruby-version
      cat > ~/.ruby-version << EOF
$(ruby --version | cut -d' ' -f2)
EOF

      # Création du fichier .ruby-gemset
      cat > ~/.ruby-gemset << EOF
devops
EOF

      log_success "✅ Environnement Ruby configuré pour IntelliJ"

      # Test de la configuration Ruby
      log_info "🧪 Test de la configuration Ruby..."
      ruby -e "puts 'Ruby fonctionne correctement'" | tee -a $LOG_FILE

      return 0
    }

    # ==========================================================
    # 5.4 FONCTION DE TEST DE BASE DE DONNÉES
    # ==========================================================

    test_mysql_connection() {
      log_section "🐬 TEST DE CONNEXION MYSQL"

      # Test 1: Connexion root
      if mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT 1" &> /dev/null; then
        log_success "✅ Connexion MySQL (root) : OK"
      else
        log_error "❌ Connexion MySQL (root) : ÉCHEC"
        return 1
      fi

      # Test 2: Vérification de la base
      if mysql -u root -p$MYSQL_ROOT_PASSWORD -e "USE $MYSQL_DATABASE" &> /dev/null; then
        log_success "✅ Base de données '$MYSQL_DATABASE' : OK"
      else
        log_error "❌ Base de données '$MYSQL_DATABASE' : ÉCHEC"
        mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
        log_success "✅ Base de données '$MYSQL_DATABASE' créée"
      fi

      # Test 3: Vérification utilisateur application
      if mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1" &> /dev/null; then
        log_success "✅ Connexion MySQL ($MYSQL_USER) : OK"
      else
        log_warn "⚠️ Utilisateur '$MYSQL_USER' non configuré, création..."
        mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
        mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"
        mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"
        log_success "✅ Utilisateur '$MYSQL_USER' créé avec succès"
      fi

      # Test 4: Test de performance
      log_info "⏱️ Test de performance MySQL..."
      mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT COUNT(*) FROM information_schema.tables" &> /dev/null
      if [ $? -eq 0 ]; then
        log_success "✅ Performance MySQL : OK"
      else
        log_error "❌ Performance MySQL : ÉCHEC"
      fi

      # Test 5: Variables importantes
      log_info "📊 Configuration MySQL :"
      mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW VARIABLES LIKE 'max_connections';" | grep -v Variable_name | tee -a $LOG_FILE
      mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';" | grep -v Variable_name | tee -a $LOG_FILE

      return 0
    }

    # ==========================================================
    # 5.5 FONCTION DE VÉRIFICATION SPRING BOOT
    # ==========================================================

    test_spring_boot_config() {
      log_section "🚀 TEST DE CONFIGURATION SPRING BOOT"

      local spring_config="/home/vagrant/projects/student-management/src/main/resources/application.properties"

      # Création du répertoire de projet
      mkdir -p /home/vagrant/projects/student-management/src/main/resources

      # Création du fichier de configuration
      cat > $spring_config << EOF
spring.application.name=student-management

# MySQL Configuration
spring.datasource.url=jdbc:mysql://192.168.56.10:3306/$MYSQL_DATABASE?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
spring.datasource.username=$MYSQL_USER
spring.datasource.password=$MYSQL_PASSWORD

# JPA Configuration
spring.jpa.show-sql=true
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect
spring.jpa.properties.hibernate.format_sql=true

# Server Configuration
server.port=8089
server.servlet.context-path=/student

# Logging
logging.level.org.springframework=INFO
logging.level.com.example=DEBUG

# Actuator pour Prometheus
management.endpoints.web.exposure.include=health,info,prometheus
management.metrics.export.prometheus.enabled=true
EOF

      log_success "✅ Fichier application.properties créé : $spring_config"

      # Vérification du fichier
      if [ -f "$spring_config" ]; then
        log_success "✅ Fichier application.properties trouvé"

        # Vérifier les paramètres
        if grep -q "spring.datasource.url.*jdbc:mysql://" $spring_config; then
          log_success "✅ Configuration JDBC correcte"
        fi

        if grep -q "spring.datasource.password.*$MYSQL_PASSWORD" $spring_config; then
          log_success "✅ Mot de passe JDBC correct"
        fi

        # Afficher la configuration
        log_info "📝 Contenu de application.properties :"
        cat $spring_config | tee -a $LOG_FILE
      else
        log_error "❌ Fichier application.properties non créé"
      fi

      return 0
    }

    # ==========================================================
    # 5.6 FONCTION DE VÉRIFICATION SERVEUR
    # ==========================================================

    test_server_config() {
      log_section "🌐 TEST DE CONFIGURATION SERVEUR"

      # Vérification des ports
      log_info "🔌 Vérification des ports :"
      sudo netstat -tlnp | grep -E "8080|8089|9000|3000|9090|3306" | tee -a $LOG_FILE

      # Vérification du firewall
      log_info "🛡️ Statut du firewall :"
      sudo ufw status 2>&1 | tee -a $LOG_FILE

      # Configuration du firewall (si actif)
      if command -v ufw &> /dev/null; then
        sudo ufw allow 8080/tcp 2>&1 | tee -a $LOG_FILE
        sudo ufw allow 8089/tcp 2>&1 | tee -a $LOG_FILE
        sudo ufw allow 9000/tcp 2>&1 | tee -a $LOG_FILE
        sudo ufw allow 3000/tcp 2>&1 | tee -a $LOG_FILE
        sudo ufw allow 9090/tcp 2>&1 | tee -a $LOG_FILE
        sudo ufw allow 3306/tcp 2>&1 | tee -a $LOG_FILE
        sudo ufw allow 22/tcp 2>&1 | tee -a $LOG_FILE
        log_success "✅ Firewall configuré"
      fi

      # Test de connectivité réseau
      log_info "📡 Test de connectivité :"
      ping -c 3 192.168.56.10 2>&1 | tee -a $LOG_FILE

      # Test DNS
      nslookup google.com &> /dev/null
      if [ $? -eq 0 ]; then
        log_success "✅ DNS : Résolution OK"
      else
        log_warn "⚠️ DNS : Résolution échouée"
      fi

      return 0
    }

    # ==========================================================
    # 5.7 FONCTION DE GÉNÉRATION DE RAPPORT
    # ==========================================================

    generate_report() {
      local report_file="/home/vagrant/devops_report.txt"

      cat > $report_file << EOF
╔═══════════════════════════════════════════════════════════════╗
║          DEVOPS ENVIRONMENT VERIFICATION REPORT             ║
╚═══════════════════════════════════════════════════════════════╝

Date: $(date)
Hostname: $(hostname)
IP Address: 192.168.56.10

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SYSTEM INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OS: $(lsb_release -d | cut -f2)
Kernel: $(uname -r)
CPU: $(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
Memory: $(free -h | grep Mem | awk '{print $2}')
Disk: $(df -h / | awk 'NR==2 {print $2}')

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RUBY ENVIRONMENT (pour IntelliJ IDEA)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ruby Version: $(ruby --version 2>/dev/null | cut -d' ' -f2)
RubyGems Version: $(gem --version 2>/dev/null)
Rails Version: $(rails --version 2>/dev/null | cut -d' ' -f2 || echo "Non installé")
Gem Home: $(gem env gemdir 2>/dev/null)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOOLS VERSIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Java: $(java --version 2>&1 | head -n1)
Maven: $(mvn -version 2>&1 | head -n1 | cut -d' ' -f3)
Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')
Jenkins: $(sudo systemctl status jenkins --no-pager 2>/dev/null | grep Active | awk '{print $3}')
Kubectl: $(kubectl version --client --output=json 2>/dev/null | grep -oP '"gitVersion":"[^"]*"' | cut -d'"' -f4 | head -n1)
Minikube: $(minikube version 2>/dev/null | head -n1 | cut -d' ' -f3 | tr -d 'v')
Terraform: $(terraform version 2>/dev/null | head -n1 | cut -d' ' -f2)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DATABASE CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Database: $MYSQL_DATABASE
User: $MYSQL_USER
Password: $MYSQL_PASSWORD
Root Password: $MYSQL_ROOT_PASSWORD
Connection URL: jdbc:mysql://192.168.56.10:3306/$MYSQL_DATABASE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SERVICES STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Jenkins: $(sudo systemctl is-active jenkins)
MySQL: $(sudo systemctl is-active mysql)
Docker: $(sudo systemctl is-active docker)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SERVICES URLs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Jenkins: http://192.168.56.10:8080
SonarQube: http://192.168.56.10:9000
Grafana: http://192.168.56.10:3000
Prometheus: http://192.168.56.10:9090
Spring Boot: http://192.168.56.10:8089/student
MySQL: jdbc:mysql://192.168.56.10:3306

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREDENTIALS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Jenkins Initial: [PROTECTED]
SonarQube: admin / [PROTECTED]
Grafana: admin / [PROTECTED]
MySQL Root: root / [PROTECTED]
MySQL App: $MYSQL_USER / [PROTECTED]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INTELLIJ IDEA CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ruby SDK: $(ruby --version 2>/dev/null)
Gem Path: $(gem env gemdir 2>/dev/null)
Project Path: /home/vagrant/projects/student-management

EOF

      log_success "✅ Rapport généré : $report_file"
      cat $report_file

      return 0
    }

    # ==========================================================
    # 5.8 DÉBUT DU PROVISIONNEMENT
    # ==========================================================

    log_section "🚀 DÉBUT DU PROVISIONNEMENT DEVOPS"
    log_info "Fichier de log : $LOG_FILE"

    # ==========================================================
    # 5.9 MISE À JOUR DU SYSTÈME
    # ==========================================================

    log_section "📦 MISE À JOUR DU SYSTÈME"

    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -y 2>&1 | tee -a $LOG_FILE
    sudo apt-get upgrade -y 2>&1 | tee -a $LOG_FILE
    sudo apt-get autoremove -y 2>&1 | tee -a $LOG_FILE

    # ==========================================================
    # 5.10 INSTALLATION DES OUTILS DE BASE
    # ==========================================================

    log_section "🛠️ INSTALLATION DES OUTILS DE BASE"

    sudo apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      software-properties-common \
      git \
      vim \
      htop \
      net-tools \
      wget \
      tree \
      jq \
      unzip \
      make \
      build-essential \
      gnupg-agent \
      dnsutils \
      netcat \
      telnet \
      gnupg2 \
      redis-tools 2>&1 | tee -a $LOG_FILE

    # ==========================================================
    # 5.11 INSTALLATION DE JAVA JDK 25 LTS
    # ==========================================================

    log_section "☕ INSTALLATION DE JAVA JDK 25 LTS"

    sudo apt-get install -y openjdk-25-jdk openjdk-25-jre 2>&1 | tee -a $LOG_FILE

    echo 'export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64' >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
    source ~/.bashrc

    java --version 2>&1 | tee -a $LOG_FILE

    # ==========================================================
    # 5.12 INSTALLATION DE RUBY (pour IntelliJ)
    # ==========================================================

    log_section "🔴 INSTALLATION DE RUBY POUR INTELLIJ"

    sudo apt-get install -y ruby-full ruby-dev ruby-bundler 2>&1 | tee -a $LOG_FILE

    # Installation des gems essentielles
    gem install bundler rake json nokogiri 2>&1 | tee -a $LOG_FILE

    ruby --version 2>&1 | tee -a $LOG_FILE

    # ==========================================================
    # 5.13 INSTALLATION DE MAVEN
    # ==========================================================

    log_section "📦 INSTALLATION DE MAVEN 3.9.9"

    MAVEN_VERSION="3.9.9"
    wget -q "https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" 2>&1 | tee -a $LOG_FILE
    sudo tar -xzf "apache-maven-${MAVEN_VERSION}-bin.tar.gz" -C /opt 2>&1 | tee -a $LOG_FILE
    sudo mv "/opt/apache-maven-${MAVEN_VERSION}" /opt/maven
    echo 'export M2_HOME=/opt/maven' >> ~/.bashrc
    echo 'export PATH=$M2_HOME/bin:$PATH' >> ~/.bashrc
    source ~/.bashrc
    rm "apache-maven-${MAVEN_VERSION}-bin.tar.gz"

    mvn --version 2>&1 | tee -a $LOG_FILE

    # ==========================================================
    # 5.14 INSTALLATION DE DOCKER
    # ==========================================================

    log_section "🐳 INSTALLATION DE DOCKER 27.x"

    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>&1 | tee -a $LOG_FILE
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y 2>&1 | tee -a $LOG_FILE
    sudo apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin \
      docker-compose 2>&1 | tee -a $LOG_FILE

    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker vagrant
    sudo usermod -aG docker jenkins 2>/dev/null || true
    # sudo chmod 666 /var/run/docker.sock # Removed for security

    docker --version 2>&1 | tee -a $LOG_FILE

    # ==========================================================
    # 5.15 INSTALLATION DE MYSQL
    # ==========================================================

    log_section "🐬 INSTALLATION DE MYSQL 8.0"

    sudo apt-get install -y mysql-server mysql-client 2>&1 | tee -a $LOG_FILE

    sudo systemctl start mysql
    sudo systemctl enable mysql

    # Configuration MySQL
    log_info "Configuration de MySQL..."

    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';" 2>&1 | tee -a $LOG_FILE
    sudo mysql -e "FLUSH PRIVILEGES;" 2>&1 | tee -a $LOG_FILE

    sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>&1 | tee -a $LOG_FILE
    sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" 2>&1 | tee -a $LOG_FILE
    sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';" 2>&1 | tee -a $LOG_FILE
    sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;" 2>&1 | tee -a $LOG_FILE

    sudo sed -i "s/bind-address.*/bind-address = 127.0.0.1/" /etc/mysql/mysql.conf.d/mysqld.cnf
    sudo systemctl restart mysql

    check_service mysql
    check_port 3306 "MySQL"

    # ==========================================================
    # 5.16 INSTALLATION DE JENKINS
    # ==========================================================

    log_section "🔧 INSTALLATION DE JENKINS"

    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null 2>&1 | tee -a $LOG_FILE

    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null

    sudo apt-get update -y 2>&1 | tee -a $LOG_FILE
    sudo apt-get install -y jenkins 2>&1 | tee -a $LOG_FILE

    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    sudo usermod -aG docker jenkins

    sleep 30

    check_service jenkins
    check_port 8080 "Jenkins"

    log_info "🔑 Mot de passe initial Jenkins :"
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword | tee -a $LOG_FILE

    # ==========================================================
    # 5.17 TÉLÉCHARGEMENT DES IMAGES DOCKER
    # ==========================================================

    log_section "🐳 TÉLÉCHARGEMENT DES IMAGES DOCKER"

    docker pull hello-world:linux 2>&1 | tee -a $LOG_FILE
    docker pull mysql:8.0.42 2>&1 | tee -a $LOG_FILE
    docker pull sonarqube:25.4.0 2>&1 | tee -a $LOG_FILE
    docker pull prom/prometheus:v3.5.0 2>&1 | tee -a $LOG_FILE
    docker pull grafana/grafana:11.5.0 2>&1 | tee -a $LOG_FILE
    docker pull jenkins/jenkins:lts-jdk25 2>&1 | tee -a $LOG_FILE

    # ==========================================================
    # 5.18 EXÉCUTION DES TESTS
    # ==========================================================

    log_section "🧪 EXÉCUTION DES TESTS DE VÉRIFICATION"

    # Test Ruby/IntelliJ
    check_ruby_environment

    # Test système
    test_server_config

    # Test MySQL
    test_mysql_connection

    # Test Spring Boot
    test_spring_boot_config

    # ==========================================================
    # 5.19 GÉNÉRATION DU RAPPORT FINAL
    # ==========================================================

    generate_report

    # ==========================================================
    # 5.20 MESSAGE FINAL
    # ==========================================================

    log_section "🎉 PROVISIONNEMENT TERMINÉ AVEC SUCCÈS !"

    cat << EOF

    ╔═══════════════════════════════════════════════════════════════╗
    ║  ✅ ENVIRONNEMENT DEVOPS PRÊT À L'EMPLOI                    ║
    ╚═══════════════════════════════════════════════════════════════╝

    🌐 SERVICES ACCESSIBLES :
    ------------------------
    🔧 Jenkins     : http://192.168.56.10:8080
    📊 SonarQube   : http://192.168.56.10:9000
    📈 Grafana     : http://192.168.56.10:3000
    📉 Prometheus  : http://192.168.56.10:9090
    🚀 Spring Boot : http://192.168.56.10:8089/student
    🐬 MySQL       : 192.168.56.10:3306

    🔑 CREDENTIALS :
    ----------------
    Jenkins    : [PROTECTED]
    SonarQube  : admin / [PROTECTED]
    Grafana    : admin / [PROTECTED]
    MySQL Root : root / [PROTECTED]
    MySQL App  : $MYSQL_USER / [PROTECTED]

    📁 INTELLIJ CONFIGURATION :
    ---------------------------
    Project Path  : /home/vagrant/projects/student-management
    Ruby Version  : $(ruby --version 2>/dev/null | cut -d' ' -f2)
    Gem Path      : $(gem env gemdir 2>/dev/null)

    📋 RAPPORT COMPLET : /home/vagrant/devops_report.txt

    💡 COMMANDES UTILES :
    ---------------------
    vagrant ssh                  # Se connecter à la VM
    cat /home/vagrant/devops_report.txt  # Voir le rapport

    🐳 Démarrer les services :
    docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=[PROTECTED] -e MYSQL_DATABASE=studentdb -p 127.0.0.1:3306:3306 mysql:8.0.42
EOF
  SHELL

  # ============================================================
  # 6. MESSAGE POST-DÉMARRAGE
  # ============================================================
  config.vm.post_up_message = <<-MESSAGE
    🎉 VM PRÊTE !
    Jenkins: http://192.168.56.10:8080
    SonarQube: http://192.168.56.10:9000
    Grafana: http://192.168.56.10:3000
  MESSAGE

end