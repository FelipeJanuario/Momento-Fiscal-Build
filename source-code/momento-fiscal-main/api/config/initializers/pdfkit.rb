# config/initializers/pdfkit.rb
PDFKit.configure do |config|
  config.default_options = {
    :page_size => 'A4',
    :print_media_type => true
  }

  config.verbose = Rails.env.development? || Rails.env.test?
end
