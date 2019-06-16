ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
   # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
   fixtures :all
   
   # Add more helper methods to be used by all tests here...
   def save_users_and_devs
      dav = users(:dav)
      dav.password = "raspberry"
      dav.save
      
      matt = users(:matt)
      matt.password = "schachmatt"
      matt.save
      
      sherlock = users(:sherlock)
      sherlock.password = "sherlocked"
      sherlock.save
      
      cato = users(:cato)
      cato.password = "123456"
      cato.save
      
      tester = users(:tester)
      tester.password = "testpassword"
      tester.save
      
      tester2 = users(:tester2)
      tester2.password = "testpassword"
      tester2.save

      torera = users(:torera)
      torera.password = "Geld"
      torera.save
      
      devs(:dav).save
      devs(:matt).save
      devs(:sherlock).save
   end
   
   def login_user(user, password, dev)
      get "/v1/auth/login?email=#{user.email}&password=#{password}&auth=" + generate_auth_token(dev)
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

   def extract_zip(file, destination)
      require 'zip'
      
      FileUtils.mkdir_p(destination)
		
      Zip::File.open(file) do |zip_file|
         zip_file.each do |f|
            fpath = File.join(destination, f.name)
            zip_file.extract(f, fpath) unless File.exist?(fpath)
         end
      end
   end

   def generate_table_object_etag(object)
		# id,table_id,user_id,visibility,uuid,file,property1Name:property1Value,property2Name:property2Value,...
		etag_string = "#{object.id},#{object.table_id},#{object.user_id},#{object.visibility},#{object.uuid},#{object.file}"

		object.properties.each do |prop|
			etag_string += ",#{prop.name}:#{prop.value}"
		end

		return Digest::MD5.hexdigest(etag_string)
	end
end
