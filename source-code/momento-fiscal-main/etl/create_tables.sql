-- Migration: Create empresas and estabelecimentos tables

-- Empresas table
CREATE TABLE IF NOT EXISTS empresas (
    id SERIAL PRIMARY KEY,
    cnpj_basico VARCHAR(8) NOT NULL UNIQUE,
    razao_social VARCHAR(255) NOT NULL,
    natureza_juridica INTEGER,
    qualificacao_responsavel INTEGER,
    capital_social DECIMAL(15,2),
    porte_empresa INTEGER,
    ente_federativo_responsavel VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS index_empresas_on_cnpj_basico ON empresas(cnpj_basico);

-- Estabelecimentos table
CREATE TABLE IF NOT EXISTS estabelecimentos (
    id SERIAL PRIMARY KEY,
    empresa_id INTEGER NOT NULL REFERENCES empresas(id),
    cnpj_completo VARCHAR(14) NOT NULL UNIQUE,
    cnpj_basico VARCHAR(8) NOT NULL,
    cnpj_ordem VARCHAR(4) NOT NULL,
    cnpj_dv VARCHAR(2) NOT NULL,
    identificador_matriz_filial INTEGER,
    nome_fantasia VARCHAR(255),
    situacao_cadastral INTEGER,
    data_situacao_cadastral DATE,
    motivo_situacao_cadastral INTEGER,
    data_inicio_atividade DATE,
    
    -- Endereço
    tipo_logradouro VARCHAR(50),
    logradouro VARCHAR(255),
    numero VARCHAR(20),
    complemento VARCHAR(255),
    bairro VARCHAR(100),
    cep VARCHAR(8),
    uf VARCHAR(2),
    municipio INTEGER,
    ddd_1 VARCHAR(4),
    telefone_1 VARCHAR(8),
    ddd_2 VARCHAR(4),
    telefone_2 VARCHAR(8),
    ddd_fax VARCHAR(4),
    fax VARCHAR(8),
    email VARCHAR(255),
    
    -- CNAE
    cnae_fiscal_principal INTEGER,
    cnae_fiscal_secundaria TEXT,
    
    -- Geolocalização
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    geocoded_at TIMESTAMP,
    
    -- Cache de dívidas SERPRO
    debt_value DECIMAL(15,2),
    debt_count INTEGER,
    debt_checked_at TIMESTAMP,
    debt_details JSONB,
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Índices
CREATE UNIQUE INDEX IF NOT EXISTS index_estabelecimentos_on_cnpj_completo ON estabelecimentos(cnpj_completo);
CREATE INDEX IF NOT EXISTS index_estabelecimentos_on_cnpj_basico ON estabelecimentos(cnpj_basico);
CREATE INDEX IF NOT EXISTS index_estabelecimentos_on_empresa_id ON estabelecimentos(empresa_id);
CREATE INDEX IF NOT EXISTS index_estabelecimentos_on_situacao_cadastral ON estabelecimentos(situacao_cadastral);
CREATE INDEX IF NOT EXISTS index_estabelecimentos_on_cep ON estabelecimentos(cep);
CREATE INDEX IF NOT EXISTS index_estabelecimentos_on_coordinates ON estabelecimentos(latitude, longitude);
CREATE INDEX IF NOT EXISTS index_estabelecimentos_on_status_and_cep ON estabelecimentos(situacao_cadastral, cep);
CREATE INDEX IF NOT EXISTS index_estabelecimentos_on_debt_cache ON estabelecimentos(debt_checked_at) WHERE debt_checked_at IS NOT NULL;

-- Schema migrations entry
INSERT INTO schema_migrations (version) VALUES ('20260107000001') ON CONFLICT DO NOTHING;
