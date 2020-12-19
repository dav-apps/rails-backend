ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
   # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
   fixtures :all
   
   # Helper methods
   def login_user(user, password, dev)
      get "/v1/auth/login?email=#{user.email}&password=#{password}", headers: {'Authorization' => generate_auth_token(dev)}
      response
   end

   def generate_session_jwt(user, dev, app_id, password)
		post "/v1/auth/session", 
			headers: {'Authorization' => generate_auth_token(devs(:sherlock)), 'Content-Type' => 'application/json'},
			params: {email: user.email, password: password, api_key: dev.api_key, app_id: app_id, device_name: "Testdevice", device_type: "Testdevice", device_os: "Ubuntu"}.to_json
		resp = JSON.parse(response.body)
		return resp["jwt"]
   end
   
   def generate_auth_token(dev)
      dev.api_key + "," + Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
   end

	def generate_table_object_etag(object)
		# id,table_id,user_id,visibility,uuid,file,property1Name:property1Value,property2Name:property2Value,...
		etag_string = "#{object.id},#{object.table_id},#{object.user_id},0,#{object.uuid},#{object.file}"

		PropertyDelegate.where(table_object_id: object.id).each do |prop|
			etag_string += ",#{prop.name}:#{prop.value}"
		end

		return Digest::MD5.hexdigest(etag_string)
	end
end
