class ActiveUserDelegate
	attr_reader :active_user
	attr_accessor :id,
		:time,
		:count_daily,
		:count_monthly,
		:count_yearly
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@time = attributes[:time]
		@count_daily = attributes[:count_daily]
		@count_monthly = attributes[:count_monthly]
		@count_yearly = attributes[:count_yearly]

		@active_user = ActiveUserMigration.find_by(id: @id)
		@active_user = ActiveUserMigration.new(id: @id) if @active_user.nil?
	end

	def attributes
		{
			id: @id,
			time: @time,
			count_daily: @count_daily,
			count_monthly: @count_monthly,
			count_yearly: @count_yearly
		}
	end

	def save
		# Copy the values to the active_user
		@active_user.time = @time
		@active_user.count_daily = @count_daily
		@active_user.count_monthly = @count_monthly
		@active_user.count_yearly = @count_yearly
		delete_old = false

		# Check the id
		if @active_user.id.nil?
			# Get the ids for the last active_user in the old and new database
			last_active_user = ActiveUser.last
			last_active_user_migration = ActiveUserMigration.last

			if !last_active_user.nil? && !last_active_user_migration.nil?
				if last_active_user.id >= last_active_user_migration.id
					@active_user.id = last_active_user.id + 1
				else
					@active_user.id = last_active_user_migration.id + 1
				end
			elsif !last_active_user.nil?
				@active_user.id = last_active_user.id + 1
			elsif !last_active_user_migration.nil?
				@active_user.id = last_active_user_migration.id + 1
			end
		else
			delete_old = true
		end

		if @active_user.save
			@id = @active_user.id

			if delete_old
				# Check if the active_user is still in the old database
				old_active_user = ActiveUser.find_by(id: @id)
				old_active_user.destroy! if !old_active_user.nil?
			end

			return true
		end

		return false
	end

	def self.where(*params)
		result = Array.new

		# Get the active_users from the new database
		ActiveUserMigration.where(params).each do |active_user|
			result.push(ActiveUserDelegate.new(active_user.attributes))
		end

		# Get the active_users from the old database
		ActiveUser.where(params).each do |active_user|
			# Check if the active_user is already in the results
			next if result.any? { |u| u.id == active_user.id }
			result.push(ActiveUserDelegate.new(active_user.attributes))
		end

		return result
	end
end