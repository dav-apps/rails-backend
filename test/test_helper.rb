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
      
      devs(:dav).save
      devs(:matt).save
      devs(:sherlock).save
   end
   
   def login_user(user, password, dev)
      get "/v1/users/login?email=#{user.email}&password=#{password}&auth=" + generate_auth_token(dev)
      response
   end
   
   def generate_auth_token(dev)
      dev.api_key + "," + Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid.to_s))
   end
end
