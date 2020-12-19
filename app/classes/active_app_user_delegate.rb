class ActiveAppUserDelegate
	attr_reader :active_app_user
	attr_accessor :id,
		:app_id,
		:time,
		:count_daily,
		:count_monthly,
		:count_yearly
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@app_id = attributes[:app_id]
		@time = attributes[:time]
		@count_daily = attributes[:count_daily]
		@count_monthly = attributes[:count_monthly]
		@count_yearly = attributes[:count_yearly]

		@active_app_user = ActiveAppUserMigration.find_by(id: @id)
		@active_app_user = ActiveAppUserMigration.new(id: @id) if @active_app_user.nil?
	end

	def attributes
		{
			id: @id,
			app_id: @app_id,
			time: @time,
			count_daily: @count_daily,
			count_monthly: @count_monthly,
			count_yearly: @count_yearly
		}
	end

	def save
		# Copy the values to the active_app_user
		@active_app_user.app_id = @app_id
		@active_app_user.time = @time
		@active_app_user.count_daily = @count_daily
		@active_app_user.count_monthly = @count_monthly
		@active_app_user.count_yearly = @count_yearly
		delete_old = false

		# Check the id
		if @active_app_user.id.nil?
			# Get the ids for the last active_app_user in the old and new database
			last_active_app_user = ActiveAppUser.last
			last_active_app_user_migration = ActiveAppUserMigration.last

			if !last_active_app_user.nil? && !last_active_app_user_migration.nil?
				if last_active_app_user.id >= last_active_app_user_migration.id
					@active_app_user.id = last_active_app_user.id + 1
				else
					@active_app_user.id = last_active_app_user_migration.id + 1
				end
			elsif !last_active_app_user.nil?
				@active_app_user.id = last_active_app_user.id + 1
			elsif !last_active_app_user_migration.nil?
				@active_app_user.id = last_active_app_user_migration.id + 1
			end
		else
			delete_old = true
		end

		if @active_app_user.save
			@id = @active_app_user.id

			if delete_old
				# Check if the active_app_user is still in the old database
				old_active_app_user = ActiveAppUser.find_by(id: @id)
				old_active_app_user.destroy! if !old_active_app_user.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the active_app_user in the old database
		active_app_user = ActiveAppUser.find_by(id: @id)
		active_app_user.destroy! if !active_app_user.nil?

		# Delete the active_app_user in the new database
		active_app_user = ActiveAppUserMigration.find_by(id: @id)
		active_app_user.destroy! if !active_app_user.nil?
	end

	def self.find_by(params)
		# Try to find the active_app_user in the new database
		active_app_user = ActiveAppUserMigration.find_by(params)
		return ActiveAppUserDelegate.new(active_app_user.attributes) if !active_app_user.nil?

		# Try to find the active_app_user in the old database
		active_app_user = ActiveAppUser.find_by(params)
		return active_app_user.nil? ? nil : ActiveAppUserDelegate.new(active_app_user.attributes)
	end

	def self.where(*params)
		result = Array.new

		# Get the active_app_users from the new database
		ActiveAppUserMigration.where(params).each do |active_app_user|
			result.push(ActiveAppUserDelegate.new(active_app_user.attributes))
		end

		# Get the active_app_users from the old database
		ActiveAppUser.where(params).each do |active_app_user|
			# Check if the active_app_user is already in the results
			next if result.any? { |u| u.id == active_app_user.id }
			result.push(ActiveAppUserDelegate.new(active_app_user.attributes))
		end

		return result
	end
end