require 'test_helper'

class PurchasesMethodsTest < ActionDispatch::IntegrationTest
	setup do
		save_users_and_devs
	end

	# create_purchase tests
	test "Missing fields in create_purchase" do
		obj = table_objects(:second)

		post "/v1/apps/object/#{obj.id}/purchase"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't create purchase without content type json" do
		obj = table_objects(:second)
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]

		post "/v1/apps/object/#{obj.id}/purchase", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create purchase with invalid jwt" do
		obj = table_objects(:second)

		post "/v1/apps/object/#{obj.id}/purchase",
			headers: {Authorization: "asdasdasd", 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end

	test "Can't create purchase without required params" do
		obj = table_objects(:seriesOfUnfortunateEventsFirstStoreBook)
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:dav)).body))["jwt"]

		post "/v1/apps/object/#{obj.id}/purchase",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2139, resp["errors"][0][0])
		assert_equal(2140, resp["errors"][1][0])
		assert_equal(2141, resp["errors"][2][0])
		assert_equal(2142, resp["errors"][3][0])
		assert_equal(2143, resp["errors"][4][0])
		assert_equal(2144, resp["errors"][5][0])
	end

	test "Can't create purchase with too short params" do
		obj = table_objects(:seriesOfUnfortunateEventsFirstStoreBook)
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:dav)).body))["jwt"]

		post "/v1/apps/object/#{obj.id}/purchase",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {
				product_image: "a",
				product_name: "a",
				provider_image: "a",
				provider_name: "a",
				price: 1200,
				currency: "eur"
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2211, resp["errors"][0][0])
		assert_equal(2212, resp["errors"][1][0])
		assert_equal(2213, resp["errors"][2][0])
		assert_equal(2214, resp["errors"][3][0])
	end

	test "Can't create purchase with too long params" do
		obj = table_objects(:seriesOfUnfortunateEventsFirstStoreBook)
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:dav)).body))["jwt"]

		post "/v1/apps/object/#{obj.id}/purchase",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {
				product_image: "a" * 65100,
				product_name: "a" * 400,
				provider_image: "a" * 65100,
				provider_name: "a" * 200,
				price: 1200,
				currency: "eur"
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2312, resp["errors"][0][0])
		assert_equal(2313, resp["errors"][1][0])
		assert_equal(2314, resp["errors"][2][0])
		assert_equal(2315, resp["errors"][3][0])
	end

	test "Can't create purchase with invalid price" do
		obj = table_objects(:seriesOfUnfortunateEventsFirstStoreBook)
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:dav)).body))["jwt"]

		post "/v1/apps/object/#{obj.id}/purchase",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {
				product_image: "http://localhost:3001/bla.png",
				product_name: "A Series of Unfortunate Events - Book the First",
				provider_image: "http://localhost:3001/snicket.png",
				provider_name: "Lemony Snicket",
				price: 12.3,
				currency: "eur"
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2408, resp["errors"][0][0])
	end

	test "Can't create purchase with not supported currency" do
		obj = table_objects(:seriesOfUnfortunateEventsFirstStoreBook)
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:dav)).body))["jwt"]

		post "/v1/apps/object/#{obj.id}/purchase",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {
				product_image: "http://localhost:3001/bla.png",
				product_name: "A Series of Unfortunate Events - Book the First",
				provider_image: "http://localhost:3001/snicket.png",
				provider_name: "Lemony Snicket",
				price: 999,
				currency: "bla"
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(1117, resp["errors"][0][0])
	end

	test "Can't create purchase for table object of user that is not a provider" do
		obj = table_objects(:second)
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]

		post "/v1/apps/object/#{obj.id}/purchase",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {
				product_image: "http://localhost:3001/bla.png",
				product_name: "A Series of Unfortunate Events - Book the First",
				provider_image: "http://localhost:3001/snicket.png",
				provider_name: "Lemony Snicket",
				price: 999,
				currency: "eur"
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(1118, resp["errors"][0][0])
	end

	test "Can't create purchase for own table object" do
		obj = table_objects(:seriesOfUnfortunateEventsFirstStoreBook)
		snicket = users(:snicket)
		jwt = (JSON.parse(login_user(snicket, "vfd", devs(:dav)).body))["jwt"]

		post "/v1/apps/object/#{obj.id}/purchase",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {
				product_image: "http://localhost:3001/bla.png",
				product_name: "A Series of Unfortunate Events - Book the First",
				provider_image: "http://localhost:3001/snicket.png",
				provider_name: "Lemony Snicket",
				price: 999,
				currency: "eur"
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(1120, resp["errors"][0][0])
	end

	test "Can't create purchase for table object that belongs to the app of another dev" do
		obj = table_objects(:seriesOfUnfortunateEventsFirstStoreBook)
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]

		post "/v1/apps/object/#{obj.id}/purchase",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {
				product_image: "http://localhost:3001/bla.png",
				product_name: "A Series of Unfortunate Events - Book the First",
				provider_image: "http://localhost:3001/snicket.png",
				provider_name: "Lemony Snicket",
				price: 999,
				currency: "eur"
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can create purchase" do
		obj = table_objects(:seriesOfUnfortunateEventsFirstStoreBook)
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:dav)).body))["jwt"]

		product_image = "http://localhost:3001/bla.png"
		product_name = "A Series of Unfortunate Events - Book the First"
		provider_image = "http://localhost:3001/snicket.png"
		provider_name = "Lemony Snicket"
		price = 1000
		currency = "eur"

		post "/v1/apps/object/#{obj.id}/purchase",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {
				product_image: product_image,
				product_name: product_name,
				provider_image: provider_image,
				provider_name: provider_name,
				price: price,
				currency: currency
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 201

		# Compare response with purchase in database
		purchase = Purchase.find_by_id(resp["id"])
		assert_equal(purchase.id, resp["id"])
		assert_equal(purchase.user_id, resp["user_id"])
		assert_equal(purchase.table_object_id, resp["table_object_id"])
		assert_equal(purchase.payment_intent_id, resp["payment_intent_id"])
		assert_equal(purchase.product_image, resp["product_image"])
		assert_equal(purchase.product_name, resp["product_name"])
		assert_equal(purchase.provider_image, resp["provider_image"])
		assert_equal(purchase.provider_name, resp["provider_name"])
		assert_equal(purchase.price, resp["price"])
		assert_equal(purchase.currency, resp["currency"])
		assert_equal(purchase.completed, resp["completed"])

		# Compare response with given params
		assert_equal(product_image, resp["product_image"])
		assert_equal(product_name, resp["product_name"])
		assert_equal(provider_image, resp["provider_image"])
		assert_equal(provider_name, resp["provider_name"])
		assert_equal(price, resp["price"])
		assert_equal(currency, resp["currency"])

		assert_equal(false, resp["completed"])
	end
end