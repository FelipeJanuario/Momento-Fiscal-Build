# Como iniciar a geocodificação em background

## 1. Via Rails Console

```bash
docker exec -it momento-fiscal-main-backend rails console
```

Dentro do console:

```ruby
# Iniciar processamento (50 empresas por lote)
GeocodeEstabelecimentosJob.perform_later(batch_size: 50)

# Ou processar mais rápido (100 por lote)
GeocodeEstabelecimentosJob.perform_later(batch_size: 100)

# Ver quantas empresas faltam geocodificar
Estabelecimento.ativas.where(latitude: nil).count
```

## 2. Automaticamente ao subir o backend

Edite `config/initializers/geocode_job.rb`:

```ruby
# Inicia geocodificação automática se há estabelecimentos sem coordenadas
Rails.application.config.after_initialize do
  if Estabelecimento.ativas.where(latitude: nil).any?
    GeocodeEstabelecimentosJob.set(wait: 1.minute).perform_later(batch_size: 50)
  end
end
```

## 3. Via Rake Task

Criar `lib/tasks/geocode.rake`:

```ruby
namespace :geocode do
  desc "Inicia geocodificação de todos os estabelecimentos"
  task start: :environment do
    pending = Estabelecimento.ativas.where(latitude: nil).count
    puts "#{pending} estabelecimentos sem coordenadas"
    
    if pending > 0
      GeocodeEstabelecimentosJob.perform_later(batch_size: 100)
      puts "Job iniciado!"
    else
      puts "Todos estabelecimentos já estão geocodificados"
    end
  end
  
  desc "Status da geocodificação"
  task status: :environment do
    total = Estabelecimento.ativas.count
    com_coords = Estabelecimento.ativas.where.not(latitude: nil).count
    sem_coords = total - com_coords
    percentual = (com_coords.to_f / total * 100).round(2)
    
    puts "Total: #{total}"
    puts "Com coordenadas: #{com_coords} (#{percentual}%)"
    puts "Sem coordenadas: #{sem_coords}"
  end
end
```

Executar:
```bash
docker exec momento-fiscal-main-backend rails geocode:start
docker exec momento-fiscal-main-backend rails geocode:status
```

## Como funciona

1. O job processa 50-100 empresas por vez
2. Aguarda 1.2 segundos entre cada (respeita limite Nominatim)
3. Quando termina o lote, aguarda 5 minutos e processa próximo lote
4. Continua até processar todas as empresas
5. As coordenadas são salvas direto no PostgreSQL

## Performance

- **1 empresa/segundo** = ~83 empresas/minuto
- **100 empresas/lote** = ~2 minutos/lote  
- **40.000 empresas** = ~13 horas processamento total
- Roda em background, não afeta a API

## Frontend

O Flutter também geocodifica on-demand e salva no backend via:
`PATCH /api/v1/debtors/:id/coordinates`
