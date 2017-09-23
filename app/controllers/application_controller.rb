class ApplicationController < ActionController::API
  
   def check_authorization(dev, api_key, signature)
      if api_key == dev.api_key
         sig = dev.id.to_s + "," + dev.user_id.to_s + "," + dev.uuid.to_s
         
         digest = OpenSSL::Digest.new('sha256')
         new_sig = Base64.strict_encode64(OpenSSL::HMAC.hexdigest(digest, dev.secret_key, sig))
         
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
