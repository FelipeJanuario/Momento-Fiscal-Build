# frozen_string_literal: true

module Api
  module V1
    # Mock controller for local development without Biddings Analyser service
    class MockBiddingsController < ApplicationController
      skip_before_action :authenticate_user!, only: %i[count_companies_in_location companies_in_location]

      def count_companies_in_location
        # Parse coordinates from params
        lat_start = params[:starting_point][0].to_f
        long_start = params[:starting_point][1].to_f
        lat_end = params[:ending_point][0].to_f
        long_end = params[:ending_point][1].to_f

        # Generate mock data based on coordinates
        locations = generate_mock_locations(lat_start, long_start, lat_end, long_end)

        render json: locations
      end

      def companies_in_location
        # Parse page
        page = params[:page]&.to_i || 1
        page_size = params[:page_size]&.to_i || 10

        # Generate mock companies
        companies = generate_mock_companies(page, page_size)

        render json: {
          companies: companies,
          total_count: 45,
          current_page: page,
          total_pages: 5
        }
      end

      private

      def generate_mock_locations(lat_start, long_start, lat_end, long_end)
        # Generate 5-10 random locations within bounds
        count = rand(5..10)
        locations = []

        count.times do |i|
          # Random point within bounds
          center_lat = lat_start + (lat_end - lat_start) * rand
          center_long = long_start + (long_end - long_start) * rand

          # Create geohash (simplified)
          geohash = "6gkzm#{('a'..'z').to_a.sample}#{i}"

          # Random debt values
          company_count = rand(5..25)
          debt_value = (company_count * rand(10000..100000)).to_i

          locations << {
            count: company_count,
            debt_value: format_currency(debt_value),
            geohash: geohash,
            center: [center_lat, center_long],
            box: [
              [center_lat - 0.01, center_long - 0.01],
              [center_lat + 0.01, center_long + 0.01]
            ]
          }
        end

        locations
      end

      def generate_mock_companies(page, page_size)
        companies = []
        start_index = (page - 1) * page_size

        page_size.times do |i|
          index = start_index + i + 1
          
          companies << {
            id: index.to_s,
            cnpj: format_cnpj(index),
            corporate_name: "Empresa #{%w[Alfa Beta Gama Delta Epsilon Zeta Eta Theta].sample} Ltda #{index}",
            fantasy_name: "#{%w[Tech Solutions Services Corp Industries Group].sample} #{index}",
            debts_value: rand(10000..500000).to_f,
            debts_count: rand(1..8),
            cadastral_status: %w[Ativa Suspensa Inapta].sample,
            juridical_nature: "Sociedade Empresária Limitada",
            address: {
              street: "Rua #{%w[das Flores dos Pinheiros Paulista Augusta].sample}",
              number: rand(1..9999).to_s,
              neighborhood: %w[Centro Jardins Pinheiros Vila\ Mariana].sample,
              city: "São Paulo",
              state: "SP",
              zip_code: format_cep(index)
            },
            email: "contato#{index}@empresa.com.br",
            phones: [
              {
                ddd: "11",
                number: "#{rand(9000..9999)}-#{rand(1000..9999)}"
              }
            ],
            company_size_cd: rand(1..5),
            main_cnae: "62.01-5-00 - Desenvolvimento de programas de computador sob encomenda",
            activity_start_date: (Date.today - rand(1..20).years).to_s,
            social_capital: format_currency(rand(10000..1000000))
          }
        end

        companies
      end

      def format_cnpj(num)
        base = format('%014d', num * 12345678)
        "#{base[0..1]}.#{base[2..4]}.#{base[5..7]}/#{base[8..11]}-#{base[12..13]}"
      end

      def format_cep(num)
        base = format('%08d', 1000000 + num)
        "#{base[0..4]}-#{base[5..7]}"
      end

      def format_currency(value)
        "R$ #{format('%.2f', value).gsub('.', ',').reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"
      end
    end
  end
end
