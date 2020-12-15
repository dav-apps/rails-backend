class PurchaseDelegate
	attr_reader :purchase
	attr_accessor :id,
		:user_id,
		:table_object_id,
		:payment_intent_id,
		:provider_name,
		:provider_image,
		:product_name,
		:product_image,
		:price,
		:currency,
		:completed,
		:created_at,
		:updated_at
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@user_id = attributes[:user_id]
		@table_object_id = attributes[:table_object_id]
		@payment_intent_id = attributes[:payment_intent_id]
		@provider_name = attributes[:provider_name]
		@provider_image = attributes[:provider_image]
		@product_name = attributes[:product_name]
		@product_image = attributes[:product_image]
		@price = attributes[:price]
		@currency = attributes[:currency]
		@completed = attributes[:completed]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@purchase = PurchaseMigration.find_by(id: @id)
		@purchase = PurchaseMigration.new(id: @id) if @purchase.nil?
	end

	def attributes
		{
			id: @id,
			user_id: @user_id,
			table_object_id: @table_object_id,
			payment_intent_id: @payment_intent_id,
			provider_name: @provider_name,
			provider_image: @provider_image,
			product_name: @product_name,
			product_image: @product_image,
			price: @price,
			currency: @currency,
			completed: @completed,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the purchase
		@purchase.user_id = @user_id
		@purchase.table_object_id = @table_object_id
		@purchase.payment_intent_id = @payment_intent_id
		@purchase.provider_name = @provider_name
		@purchase.provider_image = @provider_image
		@purchase.product_name = @product_name
		@purchase.product_image = @product_image
		@purchase.price = @price
		@purchase.currency = @currency
		@purchase.completed = @completed
		@purchase.created_at = @created_at
		@purchase.updated_at = @updated_at
		delete_old = false

		# Check the id
		if @purchase.id.nil?
			# Get the ids for the last purchase in the old and new database
			last_purchase = Purchase.last
			last_purchase_migration = PurchaseMigration.last

			if !last_purchase.nil? && !last_purchase_migration.nil?
				if last_purchase.id >= last_purchase_migration.id
					@purchase.id = last_purchase.id + 1
				else
					@purchase.id = last_purchase_migration.id + 1
				end
			elsif !last_purchase.nil?
				@purchase.id = last_purchase.id + 1
			elsif !last_purchase_migration.nil?
				@purchase.id = last_purchase_migration.id + 1
			end
		else
			delete_old = true
		end

		if @purchase.save
			@id = @purchase.id

			if delete_old
				# Check if the purchase is still in the old database
				old_purchase = Purchase.find_by(id: @id)
				old_purchase.destroy! if !old_purchase.nil?
			end

			return true
		end

		return false
	end

	def self.find_by(params)
		# Try to find the purchase in the new database
		purchase = PurchaseMigration.find_by(params)
		return PurchaseDelegate.new(purchase.attributes) if !purchase.nil?

		# Try to find the purchase in the old database
		purchase = Purchase.find_by(params)
		return purchase.nil? ? nil : PurchaseDelegate.new(purchase.attributes)
	end
end