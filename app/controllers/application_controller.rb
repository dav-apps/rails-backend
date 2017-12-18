class ApplicationController < ActionController::API
   
   after_action :set_cors_header
  
   def check_authorization(api_key, signature)
      dev = Dev.find_by(api_key: api_key)
      
      if !dev
         false
      else
         if api_key == dev.api_key
            
            new_sig = Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
            
            if new_sig == signature
               true
            else
               false
            end
         else
            false
         end
      end
   end
end
