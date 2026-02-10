# frozen_string_literal: true

desc 'Convert a file to base64'
task :file_to_base64, [:file_path] => :environment do |_, args|
  file_path = args[:file_path]

  File.open(file_path, 'rb') do |file|
    puts Base64.strict_encode64(file.read)
  end
end
