# Dockerfile para servir Flutter Web com Nginx
FROM nginx:alpine

# Copiar build do Flutter Web
COPY build/web /usr/share/nginx/html

# Copiar configuração customizada do Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta 80
EXPOSE 80

# Iniciar Nginx
CMD ["nginx", "-g", "daemon off;"]
