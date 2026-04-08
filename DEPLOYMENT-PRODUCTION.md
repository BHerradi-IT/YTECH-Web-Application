# 🚀 Guide de Déploiement Production - YTECH Web Application

## 📋 État Actuel du Déploiement

D'après les logs que vous avez partagés, voici la situation actuelle :

### ✅ **Ce qui fonctionne**
- 🟢 **Nginx configuré** avec succès sur `192.168.1.16`
- 🟢 **Configuration testée** et rechargée
- 🟢 **Frontend servi** via Nginx (HTTP 200 OK)
- 🟢 **Proxy API** configuré vers `localhost:5001`

### ❌ **Problèmes identifiés**
- 🔴 **IP 192.168.10.41** inaccessible (Failed to connect)
- 🔴 **Backend Node.js** potentiellement non démarré
- 🔴 **Variables d'environnement** à configurer

---

## 🔧 Étapes de Dépannage Immédiat

### 1️⃣ **Vérifier l'état du backend**

```bash
# Vérifier si le backend tourne
ps aux | grep node
netstat -tlnp | grep 5001

# Vérifier les logs du backend
journalctl -u ytech -f
# ou si lancé manuellement :
tail -f /var/www/YTech-Web-Application/backend/logs/app.log
```

### 2️⃣ **Démarrer le backend**

```bash
cd /var/www/YTech-Web-Application/backend

# Installer les dépendances si nécessaire
npm ci --production

# Configurer les variables d'environnement
cp .env.example .env
nano .env  # Configurer avec vos valeurs

# Démarrer le backend
npm start

# Ou avec PM2 pour production
pm2 start server.js --name ytech-backend
pm2 save
pm2 startup
```

### 3️⃣ **Tester l'API**

```bash
# Tester localement
curl http://127.0.0.1:5001/api/health

# Tester via Nginx
curl http://192.168.1.16/api/health
```

---

## 🌐 Configuration Réseau

### **Problème IP 192.168.10.41**

Cette IP ne répond pas. Plusieurs causes possibles :

1. **Interface réseau down**
   ```bash
   ip addr show
   # Si l'interface existe mais est down :
   sudo ip link set eth1 up
   sudo ip addr add 192.168.10.41/24 dev eth1
   ```

2. **Firewall bloquant**
   ```bash
   sudo ufw status
   sudo ufw allow 80/tcp
   sudo ufw allow 5001/tcp
   ```

3. **Configuration réseau incorrecte**
   ```bash
   # Vérifier la configuration
   cat /etc/netplan/*.yaml
   # Appliquer la configuration
   sudo netplan apply
   ```

---

## 🗄️ Configuration Base de Données

### **PostgreSQL Setup**

```bash
# Installer PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# Créer utilisateur et base de données
sudo -u postgres psql
CREATE USER ytech_user WITH PASSWORD 'votre_mot_de_passe';
CREATE DATABASE ytech_db OWNER ytech_user;
GRANT ALL PRIVILEGES ON DATABASE ytech_db TO ytech_user;
\q

# Configurer la connexion
sudo nano /etc/postgresql/14/main/pg_hba.conf
# Ajouter : local   ytech_db   ytech_user   md5

sudo systemctl restart postgresql
```

---

## 🔐 Variables d'Environnement Essentielles

Créez `/var/www/YTech-Web-Application/backend/.env` :

```bash
# Configuration de base
NODE_ENV=production
PORT=5001
HOST=0.0.0.0

# Frontend
FRONTEND_URL=https://ytech.app.ma
ALLOWED_ORIGINS=https://ytech.app.ma,http://192.168.1.16
TRUST_PROXY=true

# Sécurité
JWT_SECRET=votre_jwt_secret_min_32_caracteres
SESSION_SECRET=votre_session_secret_min_32_caracteres
ENCRYPTION_KEY=votre_cle_32_caracteres

# Base de données
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ytech_db
DB_USER=ytech_user
DB_PASSWORD=votre_mot_de_passe_db
DB_SSL=false

# Email (optionnel)
EMAIL_HOST=smtp.votreserveur.com
EMAIL_PORT=587
EMAIL_SECURE=false
EMAIL_USER=votre_email
EMAIL_PASS=votre_mot_de_passe_email
EMAIL_FROM=noreply@ytech.app.ma

# Admin
ADMIN_SEED_NAME=YTECH Admin
ADMIN_SEED_EMAIL=admin@ytech.app.ma
ADMIN_SEED_PASSWORD=mot_de_passe_admin_complex
ADMIN_SEED_PHONE=+212600000000
```

---

## 🚀 Scripts de Déploiement Automatisé

### **Script de déploiement complet**

```bash
#!/bin/bash
# deploy.sh

set -e

echo "🚀 Déploiement YTECH Web Application"

# Variables
PROJECT_DIR="/var/www/YTech-Web-Application"
BACKUP_DIR="/var/backups/ytech"
SERVICE_NAME="ytech"

# Créer backup
echo "📦 Création backup..."
mkdir -p $BACKUP_DIR
tar -czf "$BACKUP_DIR/ytech-$(date +%Y%m%d-%H%M%S).tar.gz" -C /var/www YTech-Web-Application

# Arrêter les services
echo "⏹️ Arrêt des services..."
pm2 stop $SERVICE_NAME || true
systemctl stop nginx || true

# Mettre à jour le code
echo "📥 Mise à jour du code..."
cd $PROJECT_DIR
git pull origin main

# Installer les dépendances
echo "📦 Installation dépendances..."
cd backend
npm ci --production

# Builder le frontend
echo "🏗️ Build frontend..."
cd ../frontend
npm ci
npm run build

# Configurer les permissions
echo "🔐 Configuration permissions..."
sudo chown -R www-data:www-data $PROJECT_DIR
sudo chmod -R 755 $PROJECT_DIR

# Démarrer les services
echo "▶️ Démarrage des services..."
cd $PROJECT_DIR/backend
pm2 start server.js --name $SERVICE_NAME
pm2 save

systemctl start nginx
systemctl reload nginx

# Vérifier le déploiement
echo "🔍 Vérification du déploiement..."
sleep 5

# Test API
if curl -f http://127.0.0.1:5001/api/health > /dev/null 2>&1; then
    echo "✅ Backend API OK"
else
    echo "❌ Backend API KO"
    exit 1
fi

# Test Frontend
if curl -f http://localhost/ > /dev/null 2>&1; then
    echo "✅ Frontend OK"
else
    echo "❌ Frontend KO"
    exit 1
fi

echo "🎉 Déploiement terminé avec succès!"
```

---

## 🔍 Monitoring et Logs

### **Configuration des logs**

```bash
# Créer les répertoires de logs
sudo mkdir -p /var/log/ytech
sudo chown www-data:www-data /var/log/ytech

# Configurer logrotate
sudo nano /etc/logrotate.d/ytech
```

Contenu pour `/etc/logrotate.d/ytech` :
```
/var/log/ytech/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        pm2 reload ytech
    endscript
}
```

### **Monitoring avec PM2**

```bash
# Installer PM2
npm install -g pm2

# Démarrer avec monitoring
pm2 start server.js --name ytech --log /var/log/ytech/app.log --out /var/log/ytech/out.log --err /var/log/ytech/error.log

# Monitoring en temps réel
pm2 monit

# Logs en temps réel
pm2 logs ytech
```

---

## 🛡️ Sécurité Production

### **SSL/TLS avec Let's Encrypt**

```bash
# Installer Certbot
sudo apt install certbot python3-certbot-nginx

# Obtenir certificat SSL
sudo certbot --nginx -d ytech.app.ma -d www.ytech.app.ma

# Renouvellement automatique
sudo crontab -e
# Ajouter : 0 12 * * * /usr/bin/certbot renew --quiet
```

### **Firewall**

```bash
# Configurer UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

---

## 📊 Vérification Finale

### **Checklist de déploiement**

- [ ] Backend Node.js démarré sur port 5001
- [ ] Frontend servi par Nginx
- [ ] Base de données PostgreSQL configurée
- [ ] Variables d'environnement configurées
- [ ] SSL/TLS activé
- [ ] Firewall configuré
- [ ] Logs configurés
- [ ] Monitoring PM2 actif
- [ ] Tests de santé passent

### **Tests finaux**

```bash
# Test complet
curl -I https://ytech.app.ma
curl -I https://ytech.app.ma/api/health

# Test des endpoints principaux
curl https://ytech.app.ma/api/auth/csrf-token
curl https://ytech.app.ma/api/quotes
```

---

## 🚨 Dépannage Rapide

### **Problèmes courants**

1. **Backend ne démarre pas**
   ```bash
   # Vérifier les logs
   pm2 logs ytech
   # Vérifier les dépendances
   cd /var/www/YTech-Web-Application/backend && npm ls
   ```

2. **API inaccessible**
   ```bash
   # Vérifier le port
   netstat -tlnp | grep 5001
   # Vérifier le proxy Nginx
   nginx -t
   ```

3. **Base de données inaccessible**
   ```bash
   # Tester la connexion
   psql -h localhost -U ytech_user -d ytech_db
   ```

---

## 🎞️ Support

Si vous rencontrez des problèmes :

1. **Vérifier les logs** : `pm2 logs ytech`
2. **Tester les services** : `curl http://localhost/api/health`
3. **Vérifier la configuration** : `nginx -t`
4. **Redémarrer les services** : `pm2 restart ytech && systemctl reload nginx`

---

**Votre application YTECH est prête pour la production !** 🚀
