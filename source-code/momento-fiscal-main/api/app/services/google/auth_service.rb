# frozen_string_literal: true

module Google
  # Service to authenticate with Google APIs using service account credentials
  class AuthService
    # @param scope [String] The scope for the Google API
    # @param key_file [String] Base64 encoded JSON key file for the service account
    def initialize(scope, key_file = ENV.fetch("GOOGLE_API_PFX_BASE64", nil))
      raise ArgumentError, "key_file must be present" if key_file.blank?

      @scope = scope
      @key_file = StringIO.new(Base64.decode64(key_file))
    end

    def call
      authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        scope:       @scope,
        json_key_io: @key_file
      )
      authorization.fetch_access_token!
      authorization
    end
  end
end
