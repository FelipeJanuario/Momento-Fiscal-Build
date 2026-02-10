#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

# Credenciais do Serpro (do arquivo .env.local)
SERPRO_CONSUMER_KEY = "hXCBy8nQx5B_xAUhxcB87s6wvLga"
SERPRO_CONSUMER_SECRET = "Sw43rQxUBdgycGrF3yfwHKxyaZAa"
AUTH_URL = "https://gateway.apiserpro.serpro.gov.br/token"

# CNPJ para teste (removendo formatação)
CNPJ_TESTE = "60872173000121"

def obter_token_acesso
  puts "🔑 Obtendo token de acesso..."
  
  uri = URI(AUTH_URL)
  request = Net::HTTP::Post.new(uri)
  request.basic_auth(SERPRO_CONSUMER_KEY, SERPRO_CONSUMER_SECRET)
  request.set_form_data("grant_type" => "client_credentials")
  
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  
  if response.is_a?(Net::HTTPSuccess)
    body = JSON.parse(response.body)
    puts "✅ Token obtido com sucesso!"
    puts "   Expira em: #{body['expires_in']} segundos"
    return body["access_token"]
  else
    puts "❌ Erro ao obter token:"
    puts "   Status: #{response.code}"
    puts "   Resposta: #{response.body}"
    return nil
  end
end

def consultar_dividas(cpf_cnpj, token)
  puts "\n🔍 Consultando dívidas ativas para: #{cpf_cnpj}"
  
  url = "https://gateway.apiserpro.serpro.gov.br/consulta-divida-ativa-df/api/v1/devedor/#{cpf_cnpj}"
  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{token}"
  
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  
  puts "\n📊 Resposta da API:"
  puts "   Status HTTP: #{response.code} #{response.message}"
  
  case response
  when Net::HTTPSuccess
    dados = JSON.parse(response.body)
    puts "\n✅ Consulta realizada com sucesso!"
    puts "\n" + "="*80
    puts "DADOS RETORNADOS:"
    puts "="*80
    puts JSON.pretty_generate(dados)
    puts "="*80
    
    # Análise dos dados
    if dados.is_a?(Array)
      puts "\n📈 Resumo:"
      puts "   Total de registros: #{dados.length}"
      
      if dados.length > 0
        total_dividas = dados.inject(0) { |sum, d| sum + (d['valor']&.to_f || 0) }
        puts "   Valor total aproximado: R$ #{format('%.2f', total_dividas)}" if total_dividas > 0
      end
    elsif dados.is_a?(Hash)
      puts "\n📋 Estrutura do objeto retornado:"
      puts "   Chaves: #{dados.keys.join(', ')}"
    end
    
  when Net::HTTPNotFound
    puts "\n✅ Nenhuma dívida ativa encontrada para este CPF/CNPJ"
    
  when Net::HTTPUnauthorized
    puts "\n❌ Erro de autorização (401)"
    puts "   Token pode estar inválido ou expirado"
    puts "   Resposta: #{response.body}"
    
  else
    puts "\n❌ Erro na consulta:"
    puts "   Status: #{response.code}"
    puts "   Resposta: #{response.body}"
  end
  
rescue StandardError => e
  puts "\n💥 Exceção capturada:"
  puts "   Tipo: #{e.class}"
  puts "   Mensagem: #{e.message}"
  puts "   Backtrace: #{e.backtrace.first(5).join("\n              ")}"
end

# Execução principal
puts "="*80
puts "TESTE DE CONSULTA API SERPRO - DÍVIDA ATIVA DF"
puts "="*80

token = obter_token_acesso

if token
  consultar_dividas(CNPJ_TESTE, token)
else
  puts "\n❌ Não foi possível obter o token. Abortando..."
end

puts "\n" + "="*80
puts "FIM DO TESTE"
puts "="*80
