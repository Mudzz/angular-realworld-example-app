# Étape 1: Build de l'application
FROM node:16 as build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm i -f
COPY . .
RUN npm run build --configuration prod

# Étape 2: Servir l'application avec NGINX
FROM nginx:alpine
COPY --from=build /app/dist/ /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]