# Guia de Deploy na AWS (EC2 + K3s)

Este guia descreve como colocar a aplicação em produção utilizando uma instância EC2 da AWS.

## 1. Criar Instância EC2

1.  Acesse o Console da AWS > **EC2** > **Launch Instance**.
2.  **Nome:** `trabalho-devops-server`
3.  **OS Image:** **Ubuntu** (Server 24.04 ou 22.04 LTS).
4.  **Instance Type:** **t3.small** (2 vCPU, 2GB RAM).
    *   *Nota: O script foi otimizado para rodar K3s (Kubernetes Leve), permitindo uso de t3.small.*
5.  **Key Pair:** Crie um novo par de chaves (`deploy-key.pem`) e **baixe-o**.
6.  **Network Settings (Security Group):**
    *   Allow SSH traffic from **Anywhere** (ou apenas seu IP).
    *   Allow HTTP traffic from the internet (Port 80).
    *   Allow HTTPS traffic from the internet (Port 443).
7.  **Storage:** Aumente para **20 GB** (ou mais) gp3.
8.  Clique em **Launch Instance**.

## 2. Preparar o Ambiente

1.  Conecte-se via SSH na sua nova instância:
    ```bash
    ssh -i "path/to/deploy-key.pem" ubuntu@SEU_IP_PUBLICO
    ```

2.  Clone o repositório (ou copie o script de setup):
    ```bash
    git clone https://github.com/SEU_USUARIO/SEU_REPO.git TRABALHO_DEVOPS
    cd TRABALHO_DEVOPS/infra
    ```

3.  Execute o script de instalação automática:
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```
    *Este script instalará Docker, K3s, Nginx Ingress Controller e Nginx Proxy.*

4.  **Importante:** Após o fim do script, saia (`exit`) e entre novamente no SSH para que as permissões do Docker tenham efeito.

## 3. Configurar CI/CD no GitHub

Para que o GitHub Actions consiga fazer o deploy automático, adicione as seguintes **Secrets** no seu repositório (*Settings > Secrets and variables > Actions*):

| Secret | Valor | Descrição |
| :--- | :--- | :--- |
| `DEPLOY_HOST` | `SEU_IP_PUBLICO` | IP da instância EC2. |
| `DEPLOY_USER` | `ubuntu` | Usuário padrão da AMI Ubuntu. |
| `DEPLOY_KEY` | Conteúdo do `deploy-key.pem` | Chave privada SSH (copie tudo, incluindo BEGIN e END). |
| `DOCKER_USERNAME` | Seu usuário Docker Hub | Para push das imagens. |
| `DOCKER_PASSWORD` | Sua senha/token Docker Hub | Para autenticação. |

## 4. Verificar o Deploy

Após configurar as secrets, faça um push na `main` para disparar o pipeline.

Quando o pipeline finalizar com sucesso:
1.  Acesse `http://SEU_IP_PUBLICO` no navegador.
2.  Você deve ver a interface do Frontend.
3.  As APIs estarão acessíveis internamente pelo Nginx.

## Troubleshooting

*   **Pods Pendentes:** Verifique se há memória suficiente. Use `kubectl top nodes` ou `free -h`.
*   **Erro de Permissão:** Garanta que rodou `usermod -aG docker $USER` (o script já faz isso) e relogou.
*   **Logs:** Use `kubectl logs -f deployment/catalog-deploy` para ver logs da aplicação.
