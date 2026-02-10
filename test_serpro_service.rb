#!/usr/bin/env ruby
# frozen_string_literal: true

# Teste do SerproDividaAtivaService
# Execute com: rails runner test_serpro_service.rb
# OU: cd source-code/momento-fiscal-main/api && rails runner ../../../test_serpro_service.rb

puts "="*80
puts "TESTE DO SERPRO DÍVIDA ATIVA SERVICE - COM CACHE"
puts "="*80

cnpj_teste = "60872173000121"
puts "\n📋 Testando CNPJ: #{cnpj_teste}"

begin
  # PRIMEIRA CONSULTA - Deve buscar do Serpro
  puts "\n" + "="*80
  puts "PRIMEIRA CONSULTA (Serpro API)"
  puts "="*80
  
  resultado1 = SerproDividaAtivaService.fetch_and_update(cnpj_teste)
  
  puts "\n✅ RESULTADO:"
  puts "   Quantidade de dívidas ativas: #{resultado1[:debt_count]}"
  puts "   Valor total: R$ #{formato_real(resultado1[:debt_value])}"
  puts "   Fonte: #{resultado1[:from_cache] ? '📦 CACHE' : '🌐 SERPRO API'}"
  
  if resultado1[:debts].any?
    puts "\n📊 Primeiras 3 dívidas:"
    resultado1[:debts].first(3).each_with_index do |divida, idx|
      puts "\n   #{idx + 1}. #{divida['numeroInscricao']}"
      puts "      Situação: #{divida['situacaoDescricao']}"
      puts "      Valor: #{divida['valorTotalConsolidadoMoeda']}"
      puts "      Regularidade: #{divida['tipoRegularidade']}"
    end
  end
  
  # Verifica o banco
  estabelecimento = Estabelecimento.find_by(cnpj_completo: cnpj_teste)
  if estabelecimento
    puts "\n✅ Estabelecimento no banco:"
    puts "   ID: #{estabelecimento.id}"
    puts "   debt_value: R$ #{formato_real(estabelecimento.debt_value || 0)}"
    puts "   debt_count: #{estabelecimento.debt_count || 0}"
    puts "   debt_checked_at: #{estabelecimento.debt_checked_at}"
    puts "   Cache válido? #{estabelecimento.debt_cache_valid? ? '✅ SIM' : '❌ NÃO'}"
  else
    puts "\n⚠️  Estabelecimento não encontrado no banco"
  end
  
  # SEGUNDA CONSULTA - Deve usar cache
  puts "\n" + "="*80
  puts "SEGUNDA CONSULTA (deve usar CACHE)"
  puts "="*80
  
  sleep 1 # Pequena pausa para simular nova requisição
  
  resultado2 = SerproDividaAtivaService.fetch_and_update(cnpj_teste)
  
  puts "\n✅ RESULTADO:"
  puts "   Quantidade de dívidas ativas: #{resultado2[:debt_count]}"
  puts "   Valor total: R$ #{formato_real(resultado2[:debt_value])}"
  puts "   Fonte: #{resultado2[:from_cache] ? '📦 CACHE ✅' : '🌐 SERPRO API (não deveria!)'}"
  puts "   Debts retornados: #{resultado2[:debts].length} (cache não retorna array completo)"
  
  if resultado2[:from_cache]
    puts "\n✅ SUCESSO! Cache funcionando corretamente!"
  else
    puts "\n⚠️  ATENÇÃO: Cache não foi usado na segunda consulta!"
  end
  
rescue StandardError => e
  puts "\n❌ ERRO: #{e.message}"
  puts e.backtrace.first(10).join("\n")
end

puts "\n" + "="*80

def formato_real(valor)
  "%.2f" % valor
end
