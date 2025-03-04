#!/bin/bash

# Variables
TIMESTAMP=$(date +%s)
CURRENT_ENV="blue"
TARGET_ENV="green"

# Détection de l'environnement actif
if grep -q "server app-green:80;" nginx.conf && ! grep -q "# server app-green:80;" nginx.conf; then
    CURRENT_ENV="green"
    TARGET_ENV="blue"
fi

echo "Current environment: $CURRENT_ENV"
echo "Target environment: $TARGET_ENV"

# 1. Construction de l'image pour le nouvel environnement
echo "Building image for $TARGET_ENV environment..."
docker build -t angular-app:$TARGET_ENV .

# 2. Démarrage du conteneur cible (s'il n'est pas déjà actif)
echo "Starting $TARGET_ENV environment..."
docker-compose up -d app-$TARGET_ENV

# 3. Vérification que le nouvel environnement fonctionne
TARGET_PORT=8081
if [ "$TARGET_ENV" = "green" ]; then
    TARGET_PORT=8082
fi

echo "Verifying $TARGET_ENV environment on port $TARGET_PORT..."
sleep 5
if curl -s http://localhost:$TARGET_PORT | grep -q "conduit"; then
    echo "✅ $TARGET_ENV environment is working correctly"
else
    echo "❌ $TARGET_ENV environment verification failed"
    exit 1
fi

# 4. Modification de la configuration NGINX
echo "Updating NGINX configuration..."
if [ "$CURRENT_ENV" = "blue" ]; then
    # Activer Green, désactiver Blue
    sed -i 's/server app-blue:80;/# server app-blue:80;/' nginx.conf
    sed -i 's/# server app-green:80;/server app-green:80;/' nginx.conf
else
    # Activer Blue, désactiver Green
    sed -i 's/server app-green:80;/# server app-green:80;/' nginx.conf
    sed -i 's/# server app-blue:80;/server app-blue:80;/' nginx.conf
fi

# 5. Rechargement de NGINX
echo "Reloading NGINX configuration..."
docker-compose exec -T proxy nginx -s reload

# 6. Vérification finale
echo "Verifying final deployment..."
sleep 2
if curl -s http://localhost:80 | grep -q "conduit"; then
    echo "✅ Production deployment successful!"
else
    echo "❌ Production verification failed"
    exit 1
fi

echo "Deployment completed successfully!"
