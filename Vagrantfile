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
  config.vm.synced_folder ".", "/vagrant", owner: "vagrant", group: "vagrant", mount_options: ["dmode=775", "fmode=664"]
  config.vm.synced_folder "./projects", "/home/vagrant/projects", create: true, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775", "fmode=664"]
  config.vm.synced_folder "./.idea", "/home/vagrant/.idea", create: true, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775", "fmode=664"]

  # ============================================================
  # 5. PROVISIONNEMENT COMPLET PROFESSIONNEL
  # ============================================================
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    #!/bin/bash

    # ==========================================================
    # 5.1 VARIABLES GLOBALES
    # ==========================================================

    RED='\\033[0;31m'
    GREEN='\\033[0;32m'
    YELLOW='\\033[1;33m'
    BLUE='\\033[0;34m'
    PURPLE='\\033[0;35m'
    CYAN='\\033[0;36m'
    NC='\\033[0m'

    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
    MYSQL_DATABASE="studentdb"
    MYSQL_USER="spring"
    MYSQL_PASSWORD=$(openssl rand -base64 12)

    LOG_FILE="/home/vagrant/provision.log"
    touch $LOG_FILE

    # ==========================================================
    # 5.2 FONCTIONS DE LOGGING
    # ==========================================================

    log_info() { echo -e "${GREEN}[INFO]${NC} $1" | tee -a $LOG_FILE; }
    log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a $LOG_FILE; }
    log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE; }
    log_success() { echo -e "${PURPLE}[SUCCESS]${NC} $1" | tee -a $LOG_FILE; }
    log_section() {
      echo "" | tee -a $LOG_FILE
      echo -e "${CYAN}============================================================${NC}" | tee -a $LOG_FILE
      echo -e "${CYAN}  $1${NC}" | tee -a $LOG_FILE
      echo -e "${CYAN}============================================================${NC}" | tee -a $LOG_FILE
      echo "" | tee -a $LOG_FILE
    }

    # ==========================================================
    # 5.3 FONCTIONS DE VÉRIFICATION ET UTILITAIRES
    # ==========================================================

    check_service() {
      if systemctl is-active --quiet "$1"; then
        log_success "✅ Service $1 est actif"
      else
        log_error "❌ Service $1 n'est pas actif"
      fi
    }

    check_port() {
      if netstat -tlnp 2>/dev/null | grep -q ":$1 "; then
        log_success "✅ Port $1 ($2) est en écoute"
      else
        log_error "❌ Port $1 ($2) n'est pas en écoute"
      fi
    }

    check_ruby_environment() {
      log_section "🔴 VÉRIFICATION DE L'ENVIRONNEMENT RUBY POUR INTELLIJ"

      if command -v ruby &> /dev/null; then
        RUBY_VERSION=$(ruby --version | cut -d' ' -f2)
        log_success "✅ Ruby version $RUBY_VERSION installé"
      else
        log_warn "⚠️ Ruby non trouvé, installation..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ruby-full ruby-dev ruby-bundler
      fi

      if command -v rails &> /dev/null; then
        RAILS_VERSION=$(rails --version | cut -d' ' -f2)
        log_success "✅ Rails version $RAILS_VERSION installé"
      fi

      if command -v gem &> /dev/null; then
        GEM_VERSION=$(gem --version)
        log_success "✅ RubyGems version $GEM_VERSION installé"
      else
        log_error "❌ RubyGems non trouvé"
      fi

      log_info "📦 Installation des gems pour IntelliJ..."
      sudo gem install bundler rake json 2>&1 | tee -a $LOG_FILE

      log_info "📂 Chemins Ruby :"
      gem env | tee -a $LOG_FILE

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

      echo 'export RUBY_HOME=/usr/bin/ruby' >> ~/.bashrc
      echo 'export GEM_HOME=$(ruby -e "puts Gem.user_dir")' >> ~/.bashrc
      echo 'export PATH=$GEM_HOME/bin:$PATH' >> ~/.bashrc
      source ~/.bashrc

      cat > ~/.ruby-version << EOF
$(ruby --version | cut -d' ' -f2)
EOF

      cat > ~/.ruby-gemset << EOF
devops
EOF

      log_success "✅ Environnement Ruby configuré pour IntelliJ"
      return 0
    }

    # ==========================================================
    # 5.4 FONCTION DE TEST DE BASE DE DONNÉES
    # ==========================================================

    test_mysql_connection() {
      log_section "🐬 TEST DE CONNEXION MYSQL"

      if mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1" &> /dev/null; then
        log_success "✅ Connexion MySQL (root) : OK"
      else
        log_error "❌ Connexion MySQL (root) : ÉCHEC"
        return 1
      fi

      if mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE $MYSQL_DATABASE" &> /dev/null; then
        log_success "✅ Base de données '$MYSQL_DATABASE' : OK"
      else
        log_error "❌ Base de données '$MYSQL_DATABASE' : ÉCHEC"
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
        log_success "✅ Base de données '$MYSQL_DATABASE' créée"
      fi

      if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" &> /dev/null; then
        log_success "✅ Connexion MySQL ($MYSQL_USER) : OK"
      else
        log_warn "⚠️ Utilisateur '$MYSQL_USER' non configuré, création..."
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
        log_success "✅ Utilisateur '$MYSQL_USER' créé avec succès"
      fi

      mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW VARIABLES LIKE 'max_connections';" | grep -v Variable_name | tee -a $LOG_FILE
      return 0
    }

    # ==========================================================
    # 5.5 FONCTION DE VÉRIFICATION SPRING BOOT
    # ==========================================================

    test_spring_boot_config() {
      log_section "🚀 TEST DE CONFIGURATION SPRING BOOT"

      local spring_config="/home/vagrant/projects/student-management/src/main/resources/application.properties"
      mkdir -p /home/vagrant/projects/student-management/src/main/resources

      cat > "$spring_config" << EOF
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

# Actuator pour Prometheus
management.endpoints.web.exposure.include=health,info,prometheus
management.metrics.export.prometheus.enabled=true
EOF

      log_success "✅ Fichier application.properties configuré : $spring_config"
      return 0
    }

    # ==========================================================
    # 5.6 FONCTION DE VÉRIFICATION SERVEUR
    # ==========================================================

    test_server_config() {
      log_section "🌐 TEST DE CONFIGURATION SERVEUR"
      sudo netstat -tlnp | grep -E "8080|8089|9000|3000|9090|3306" | tee -a $LOG_FILE
      return 0
    }

    # ==========================================================
    # 5.7 FONCTION DE GÉNÉRATION DE RAPPORT
    # ==========================================================

    generate_report() {
      local report_file="/home/vagrant/devops_report.txt"
      cat > "$report_file" << EOF
================================================================
          DEVOPS ENVIRONMENT VERIFICATION REPORT
================================================================

Date: $(date)
Hostname: $(hostname)
IP Address: 192.168.56.10

DATABASE CONFIGURATION
----------------------
Database: $MYSQL_DATABASE
User: $MYSQL_USER
Password: $MYSQL_PASSWORD
Root Password: $MYSQL_ROOT_PASSWORD
Connection URL: jdbc:mysql://192.168.56.10:3306/$MYSQL_DATABASE

EOF
      log_success "✅ Rapport généré : $report_file"
    }

    # ==========================================================
    # 5.8 DÉBUT DU PROVISIONNEMENT
    # ==========================================================

    log_section "🚀 DÉBUT DU PROVISIONNEMENT DEVOPS"

    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -y 2>&1 | tee -a $LOG_FILE
    sudo apt-get upgrade -y 2>&1 | tee -a $LOG_FILE
    sudo apt-get autoremove -y 2>&1 | tee -a $LOG_FILE

    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common git vim htop net-tools wget tree jq unzip make build-essential dnsutils netcat-traditional telnet redis-tools 2>&1 | tee -a $LOG_FILE

    log_section "☕ INSTALLATION DE JAVA JDK"
    sudo apt-get install -y openjdk-25-jdk openjdk-25-jre 2>&1 | tee -a $LOG_FILE
    echo 'export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64' >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc

    log_section "🔴 INSTALLATION DE RUBY POUR INTELLIJ"
    sudo apt-get install -y ruby-full ruby-dev ruby-bundler 2>&1 | tee -a $LOG_FILE
    sudo gem install bundler rake json nokogiri 2>&1 | tee -a $LOG_FILE

    log_section "📦 INSTALLATION DE MAVEN"
    MAVEN_VERSION="3.9.9"
    wget -q "https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
    sudo tar -xzf "apache-maven-${MAVEN_VERSION}-bin.tar.gz" -C /opt
    sudo mv "/opt/apache-maven-${MAVEN_VERSION}" /opt/maven
    echo 'export M2_HOME=/opt/maven' >> ~/.bashrc
    echo 'export PATH=$M2_HOME/bin:$PATH' >> ~/.bashrc
    rm "apache-maven-${MAVEN_VERSION}-bin.tar.gz"

    log_section "🐳 INSTALLATION DE DOCKER"
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    sudo usermod -aG docker vagrant
    sudo usermod -aG docker jenkins 2>/dev/null || true

    log_section "🐬 INSTALLATION DE MYSQL"
    sudo apt-get install -y mysql-server mysql-client
    sudo systemctl enable --now mysql
    
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
    sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"
    sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
    
    # Écoute sur 0.0.0.0 pour permettre les connexions depuis la machine hôte
    sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
    sudo systemctl restart mysql
    check_service mysql
    check_port 3306 "MySQL"

    log_section "🔧 INSTALLATION DE JENKINS"
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y jenkins
    sudo systemctl enable --now jenkins
    sudo usermod -aG docker jenkins || true

    log_section "🐳 TÉLÉCHARGEMENT DES IMAGES DOCKER"
    docker pull hello-world:linux 2>&1 | tee -a $LOG_FILE
    docker pull mysql:8.0.42 2>&1 | tee -a $LOG_FILE
    docker pull sonarqube:25.4.0 2>&1 | tee -a $LOG_FILE
    docker pull prom/prometheus:v3.5.0 2>&1 | tee -a $LOG_FILE
    docker pull grafana/grafana:11.5.0 2>&1 | tee -a $LOG_FILE
    docker pull jenkins/jenkins:lts-jdk25 2>&1 | tee -a $LOG_FILE

    log_section "🧪 EXÉCUTION DES TESTS DE VÉRIFICATION"
    check_ruby_environment
    test_server_config
    test_mysql_connection
    test_spring_boot_config
    generate_report

    log_section "🎉 PROVISIONNEMENT TERMINÉ AVEC SUCCÈS !"
    cat /home/vagrant/devops_report.txt
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