#!/bin/bash
set -e

# Cores para output
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}>>> Iniciando Setup da VM para Kubernetes (K3s)...${NC}"

# 1. Atualizar sistema
sudo apt-get update && sudo apt-get upgrade -y

# 2. Instalar Docker (Ainda útil para build de imagens locais, se necessário)
echo -e "${GREEN}>>> Instalando Docker...${NC}"
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

# 3. Instalar K3s (Lightweight Kubernetes)
# Desabilitamos o Traefik (padrão do K3s) para usar o Nginx Ingress Controller e manter compatibilidade com seus YAMLs
echo -e "${GREEN}>>> Instalando K3s (sem Traefik)...${NC}"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# Configura permissão para o usuário padrão acessar o kubectl
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
sudo chmod 600 ~/.kube/config

# Adiciona alias e autocomplete
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc

# 4. Instalar Nginx Ingress Controller (Compatível com seus manifestos)
echo -e "${GREEN}>>> Instalando Nginx Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml

# Esperar o Ingress Controller subir
echo -e "${GREEN}>>> Aguardando Ingress Controller iniciar (pode levar 1-2 min)...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 5. Instalar Gateway Externo (Proxy Reverso na VM)
echo -e "${GREEN}>>> Instalando NGINX (Gateway Externo)...${NC}"
sudo apt-get install -y nginx

# Descobrir a porta NodePort do Ingress Controller
HTTP_NODE_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

echo -e "${GREEN}>>> Configurando NGINX da VM para apontar para o Ingress (Porta $HTTP_NODE_PORT)...${NC}"

sudo tee /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    
    proxy_connect_timeout       600;
    proxy_send_timeout          600;
    proxy_read_timeout          600;
    send_timeout                600;

    location / {
        proxy_pass http://127.0.0.1:$HTTP_NODE_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

sudo systemctl restart nginx

echo -e "${GREEN}>>> SETUP CONCLUÍDO!${NC}"
echo "K3s instalado e rodando."
