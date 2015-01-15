require_relative '../../app/security/hmac_authorisation'

module Hacienda
  class Halt

    def initialize(app, hmac_authorisation = Security::HMACAuthorisation.new(app.settings))
      @app = app
      @hmac_authorisation = hmac_authorisation
    end

    def unauthorised(request)
      @app.halt 401 unless @hmac_authorisation.authorised?(request)
    end
  end
end