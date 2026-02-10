FROM python:3.11-slim

WORKDIR /app

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar script
COPY import_cnpj.py .

# Volume para os dados
VOLUME ["/cnpjs"]

CMD ["python", "import_cnpj.py", "--limit", "100"]
