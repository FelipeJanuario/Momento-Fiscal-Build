# frozen_string_literal: true

# Read the pfx file and get the private key and certificate
class ReadPfxFileService
  def initialize(io, password)
    @io = io
    @password = password

    raise ArgumentError, "io must be a IO object" unless io.is_a?(IO)
  end

  # Read the pfx file and get the private key and certificate
  # @return [Array<String, String>] The private key and certificate
  def call
    pkcs12 = OpenSSL::PKCS12.new(@io.read, @password)

    [
      pkcs12.key.to_s,
      pkcs12.certificate.to_s
    ]
  end
end
