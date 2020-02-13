require 'test_helper'

class ProvidersMethodsTest < ActionDispatch::IntegrationTest
	setup do
		save_users_and_devs
	end

	# create_provider tests
	test "Missing fields in create_provider" do
		post "/v1/provider"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't create provider with invalid jwt" do
		post "/v1/provider", headers: {Authorization: 'asdasdasd'}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end

	test "Can't create provider from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:matt)).body))["jwt"]

		post "/v1/provider", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create provider for user that already has a provider" do
		snicket = users(:snicket)
		jwt = (JSON.parse(login_user(snicket, "vfd", devs(:sherlock)).body))["jwt"]

		post "/v1/provider", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 409
		assert_equal(2910, resp["errors"][0][0])
	end

	test "Can create provider" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]

		post "/v1/provider", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 201
		
		# Get the provider and check the account id
		provider = Provider.find_by(user_id: matt.id)
		assert_equal(provider.stripe_account_id, resp["stripe_account_id"])

		# Delete the account
		Stripe::Account.delete(provider.stripe_account_id)
	end
end