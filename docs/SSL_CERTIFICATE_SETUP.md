# Configuração de Certificado SSL Válido

## Problema
O site está usando um certificado SSL autoassinado (self-signed), causando o aviso "Não seguro" nos navegadores.

## Solução
Instalar um certificado SSL válido e gratuito do **Let's Encrypt** usando Certbot.

---

## Passo a Passo de Instalação

### 1. Conectar ao Servidor
```bash
ssh root@165.22.136.67
```

### 2. Instalar Certbot
```bash
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx
```

### 3. Obter Certificado SSL

**Opção A: Método Automático (Recomendado)**
```bash
# Certbot configurará automaticamente o nginx
sudo certbot --nginx -d momentofiscal.com.br -d www.momentofiscal.com.br
```

**Opção B: Método Manual**
```bash
# Parar nginx
sudo systemctl stop nginx

# Obter certificado
sudo certbot certonly --standalone \
  -d momentofiscal.com.br \
  -d www.momentofiscal.com.br \
  --email seu-email@exemplo.com \
  --agree-tos

# Copiar nova configuração
sudo cp /caminho/nginx-https-letsencrypt.conf /etc/nginx/sites-available/momentofiscal

# Reiniciar nginx
sudo systemctl start nginx
sudo nginx -t
sudo systemctl reload nginx
```

### 4. Configurar Renovação Automática
```bash
# Testar renovação
sudo certbot renew --dry-run

# Habilitar renovação automática
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

### 5. Verificar Status
```bash
# Verificar certificado
sudo certbot certificates

# Verificar timer de renovação
sudo systemctl status certbot.timer
```

---

## Estrutura de Arquivos Let's Encrypt

Após a instalação, os certificados estarão em:
```
/etc/letsencrypt/live/momentofiscal.com.br/
├── fullchain.pem    # Certificado completo (usar no nginx)
├── privkey.pem      # Chave privada (usar no nginx)
├── cert.pem         # Certificado único
└── chain.pem        # Cadeia de certificados
```

---

## Configuração Nginx

O arquivo [nginx-https-letsencrypt.conf](nginx-https-letsencrypt.conf) já está configurado para usar os certificados Let's Encrypt:

```nginx
ssl_certificate /etc/letsencrypt/live/momentofiscal.com.br/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/momentofiscal.com.br/privkey.pem;
```

---

## Renovação Automática

O Certbot configurará automaticamente a renovação via systemd timer:

```bash
# Verificar quando a próxima renovação está agendada
sudo systemctl list-timers certbot.timer

# Renovar manualmente (se necessário)
sudo certbot renew

# Ver logs de renovação
sudo journalctl -u certbot.timer
```

Os certificados Let's Encrypt são válidos por **90 dias** e serão renovados automaticamente 30 dias antes do vencimento.

---

## Verificação Final

Após a instalação, você pode verificar se o certificado está correto:

1. **No navegador**: Acesse https://momentofiscal.com.br e verifique se o cadeado aparece verde
2. **SSL Labs**: https://www.ssllabs.com/ssltest/analyze.html?d=momentofiscal.com.br
3. **Via comando**:
   ```bash
   openssl s_client -connect momentofiscal.com.br:443 -servername momentofiscal.com.br
   ```

---

## Troubleshooting

### Erro: Port 80 já está em uso
```bash
# Parar nginx temporariamente
sudo systemctl stop nginx

# Obter certificado
sudo certbot certonly --standalone -d momentofiscal.com.br -d www.momentofiscal.com.br

# Iniciar nginx novamente
sudo systemctl start nginx
```

### Erro: DNS não está apontando para o servidor
Verifique se os registros DNS estão corretos:
```bash
dig momentofiscal.com.br +short
dig www.momentofiscal.com.br +short
```
Ambos devem retornar: `165.22.136.67`

### Erro: Firewall bloqueando porta 443
```bash
sudo ufw allow 443/tcp
sudo ufw reload
```

---

## Recursos Adicionais

- **Let's Encrypt**: https://letsencrypt.org/
- **Certbot**: https://certbot.eff.org/
- **Nginx SSL Guide**: https://nginx.org/en/docs/http/configuring_https_servers.html
