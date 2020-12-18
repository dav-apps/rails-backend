class ApplicationController < ActionController::API
   def check_authorization(api_key, signature)
      dev = DevDelegate.find_by(api_key: api_key)
      
      if !dev
         false
      else
         if api_key == dev.api_key
            Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid)) == signature
         else
            false
         end
      end
	end
	
	def validate_url(url)
      /\A#{URI::regexp}\z/.match?(url)
   end

   def get_file_size(file)
      size = 0

      if file.class == StringIO
         size = file.size
      else
         size = File.size(file)
      end

      return size
   end
	
	def get_file_size_of_table_object(obj_id)
      obj = TableObject.find_by_id(obj_id)

		if !obj
			return
		end
		
      obj.properties.each do |prop| # Get the size property of the table_object
         if prop.name == "size"
            return prop.value.to_i
         end
      end

      # If size property was not saved, get file size directly from Azure
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]
      client = Azure::Blob::BlobService.new

      begin
         # Check if the object is a file
         blob = client.get_blob(ENV['AZURE_FILES_CONTAINER_NAME'], "#{obj.table.app_id}/#{obj.id}")
         return blob[0].properties[:content_length].to_i # The size of the file in bytes
      rescue Exception => e
         puts e
      end

      return 0
   end

   def save_email_to_stripe_customer(user)
      if user.stripe_customer_id
         begin
            customer = Stripe::Customer.retrieve(user.stripe_customer_id)
            if customer
               customer.email = user.email
               customer.save
            end
         rescue => e
         end
      end
	end
	
	def generate_table_object_etag(object)
		# id,table_id,user_id,visibility,uuid,file,property1Name:property1Value,property2Name:property2Value,...
		etag_string = "#{object.id},#{object.table_id},#{object.user_id},0,#{object.uuid},#{object.file}"

		PropertyDelegate.where(table_object_id: object.id).each do |prop|
			etag_string += ",#{prop.name}:#{prop.value}"
		end

		return Digest::MD5.hexdigest(etag_string)
	end

	def get_jwt_from_header(auth_header)
		# session JWT: header.payload.signature.session_id
		# Try to get the session id. If there is no session id, this is a normal jwt and the session id is 0
		return nil if auth_header.nil?

		jwt_parts = auth_header.split(' ').last.split('.')

		jwt = jwt_parts[0..2].join('.')
		session_id = jwt_parts[3].to_i

		return [jwt, session_id]
	end

	def get_authorization_header
		request.headers['HTTP_AUTHORIZATION']
	end
	
	def get_content_type_header
		type = request.headers["Content-Type"]
		type = request.headers["CONTENT_TYPE"] if type == nil
		type = request.headers["HTTP_CONTENT_TYPE"] if type == nil
		return type
	end
end