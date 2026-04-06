-- =============================================================
-- GRANT PREMIUM OURO — Script para Workbench de Banco de Dados
-- =============================================================
-- Projeto : Momento Fiscal
-- Plano   : Ouro (plan_ouro)
-- Efeito  : Libera acesso Premium Ouro para usuários de teste
--           sem passar pelo Google Play / Apple Store / Stripe
--
-- Tabelas afetadas:
--   - users              → ios_plan, subscription_status, test_features_override
--   - google_subscriptions → subscription_id, purchase_token
--   - free_plan_usages   → status
--
-- COBERTURA:
--   ✅ App Android   → google_subscriptions + ios_plan
--   ✅ App iOS       → ios_plan + subscription_status
--   ✅ Navegador Web → test_features_override (bypass do Stripe Entitlements)
--
-- PRÉ-REQUISITO: a migration 20260329000000_add_test_features_override_to_users
-- deve ter sido executada (rails db:migrate) antes de rodar o bloco [1].
--
-- ATENÇÃO: substitua os UUIDs abaixo pelos IDs reais dos usuários.
-- Para descobrir o ID por e-mail, use a query de lookup no final.
-- =============================================================


-- -------------------------------------------------------------
-- [0] LOOKUP — Encontrar UUIDs por e-mail (execute ANTES)
-- -------------------------------------------------------------
/*
SELECT id, email, name, ios_plan, subscription_status, test_features_override
FROM users
WHERE email IN (
  'email1@exemplo.com',
  'email2@exemplo.com'
);
*/


-- =============================================================
-- [1] UPGRADE → PLANO OURO
-- =============================================================

BEGIN;

  -- Remove google_subscription existente (evita duplicata, pois
  -- o índice em user_id não é UNIQUE, mas cada usuário deve ter
  -- apenas um registro ativo)
  DELETE FROM google_subscriptions
  WHERE user_id IN (
    -- Cole os UUIDs abaixo, um por linha, entre aspas simples
    'UUID-1-AQUI',
    'UUID-2-AQUI'
  );

  -- Cria nova assinatura Google vinculada ao plan_ouro
  INSERT INTO google_subscriptions
    (id, user_id, subscription_id, purchase_token, created_at, updated_at)
  SELECT
    gen_random_uuid(),
    u.id,
    'plan_ouro',
    'test_grant_ouro_' || SUBSTRING(u.id::text, 1, 8),
    NOW(),
    NOW()
  FROM users u
  WHERE u.id IN (
    'UUID-1-AQUI',
    'UUID-2-AQUI'
  );

  -- Ativa flags de assinatura diretamente no usuário
  -- ios_plan = true  → app mobile ignora tela de seleção de plano
  -- subscription_status = 'active' → consistente com webhook Stripe pós-compra
  -- test_features_override → libera features do Plano Ouro para o navegador web
  --   (bypass do Stripe Entitlements — funciona após rails db:migrate)
  UPDATE users
  SET
    ios_plan               = true,
    subscription_status    = 'active',
    test_features_override = ARRAY['limitless_proposals', 'email_notification'],
    updated_at             = NOW()
  WHERE id IN (
    'UUID-1-AQUI',
    'UUID-2-AQUI'
  );

  -- Marca free_plan_usage como 'upgraded' para quem tiver
  UPDATE free_plan_usages
  SET
    status     = 'upgraded',
    updated_at = NOW()
  WHERE user_id IN (
    'UUID-1-AQUI',
    'UUID-2-AQUI'
  )
  AND status != 'upgraded';

COMMIT;

-- Verificação pós-upgrade
SELECT
  u.id,
  u.email,
  u.name,
  u.ios_plan,
  u.subscription_status,
  u.test_features_override,
  gs.subscription_id,
  gs.purchase_token,
  fpu.status AS free_plan_status
FROM users u
LEFT JOIN google_subscriptions gs ON gs.user_id = u.id
LEFT JOIN free_plan_usages fpu    ON fpu.user_id = u.id
WHERE u.id IN (
  'UUID-1-AQUI',
  'UUID-2-AQUI'
);


-- =============================================================
-- [2] REVERTER → PLANO FREE
-- =============================================================
-- Execute este bloco para desfazer o acesso concedido acima.
-- =============================================================

/*

BEGIN;

  -- Remove a assinatura Google
  DELETE FROM google_subscriptions
  WHERE user_id IN (
    'UUID-1-AQUI',
    'UUID-2-AQUI'
  );

  -- Reverte flags de assinatura e limpa o override de features
  UPDATE users
  SET
    ios_plan               = false,
    subscription_status    = 'inactive',
    test_features_override = ARRAY[]::text[],
    updated_at             = NOW()
  WHERE id IN (
    'UUID-1-AQUI',
    'UUID-2-AQUI'
  );

  -- Reativa o free_plan_usage (cria se não existir, atualiza se existir)
  INSERT INTO free_plan_usages
    (user_id, status, created_at, updated_at)
  SELECT
    u.id,
    'active',
    NOW(),
    NOW()
  FROM users u
  WHERE u.id IN (
    'UUID-1-AQUI',
    'UUID-2-AQUI'
  )
  ON CONFLICT (user_id)
    DO UPDATE SET
      status     = 'active',
      updated_at = NOW();

COMMIT;

-- Verificação pós-reversão
SELECT
  u.id,
  u.email,
  u.name,
  u.ios_plan,
  u.subscription_status,
  u.test_features_override,
  gs.subscription_id,
  fpu.status AS free_plan_status
FROM users u
LEFT JOIN google_subscriptions gs ON gs.user_id = u.id
LEFT JOIN free_plan_usages fpu    ON fpu.user_id = u.id
WHERE u.id IN (
  'UUID-1-AQUI',
  'UUID-2-AQUI'
);

*/
