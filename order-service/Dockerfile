# Estágio 1: Builder
FROM python:3.12-slim AS builder

WORKDIR /app

COPY requirements.txt .

# Instalamos as dependências numa pasta separada (/install)
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Estágio 2: Runtime
FROM python:3.12-slim

WORKDIR /app

# Cria usuário não-root por segurança
RUN useradd -m appuser && chown -R appuser /app

# Copia apenas as bibliotecas instaladas do estágio anterior
COPY --from=builder /install /usr/local

# Copia o código fonte
COPY app ./app

# Muda para o usuário seguro
USER appuser

# Expõe a porta do serviço
EXPOSE 8002

# Comando de inicialização
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8002"]
