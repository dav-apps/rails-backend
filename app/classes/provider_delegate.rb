class ProviderDelegate
	attr_reader :provider
	attr_accessor :id, :user_id, :stripe_account_id, :created_at, :updated_at

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@user_id = attributes[:user_id]
		@stripe_account_id = attributes[:stripe_account_id]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@provider = ProviderMigration.find_by(id: @id)
		@provider = ProviderMigration.new(id: @id) if @provider.nil?
	end

	def attributes
		{
			id: @id,
			user_id: @user_id,
			stripe_account_id: @stripe_account_id,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the provider
		@provider.user_id = @user_id
		@provider.stripe_account_id = @stripe_account_id
		@provider.created_at = @created_at
		@provider.updated_at = @updated_at
		delete_old = false

		# Check the id
		if @provider.id.nil?
			# Get the ids for the last provider in the old and new database
			last_provider = Provider.last
			last_provider_migration = ProviderMigration.last

			if !last_provider.nil? && !last_provider_migration.nil?
				if last_provider.id >= last_provider_migration.id
					@provider.id = last_provider.id + 1
				else
					@provider.id = last_provider_migration.id + 1
				end
			elsif !last_provider.nil?
				@provider.id = last_provider.id + 1
			elsif !last_provider_migration.nil?
				@provider.id = last_provider_migration.id + 1
			end
		else
			delete_old = true
		end

		if @provider.save
			@id = @provider.id
			@created_at = @provider.created_at
			@updated_at = @provider.updated_at

			if delete_old
				# Check if the provider is still in the old database
				old_provider = Provider.find_by(id: @id)
				old_provider.destroy! if !old_provider.nil?
			end

			return true
		end

		return false
	end

	def self.find_by(params)
		# Try to find the provider in the new database
		provider = ProviderMigration.find_by(params)
		return ProviderDelegate.new(provider.attributes) if !provider.nil?

		# Try to find the provider in the old database
		provider = Provider.find_by(params)
		return provider.nil? ? nil : ProviderDelegate.new(provider.attributes)
	end
end