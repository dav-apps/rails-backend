namespace :migration do
	task migrate_users: :environment do
		User.all.each do |user|
			next if UserMigration.exists?(id: user.id)

			created = UserMigration.create(
				id: user.id,
				first_name: user.username,
				email: user.email,
				confirmed: user.confirmed,
				password_digest: user.password_digest,
				email_confirmation_token: user.email_confirmation_token,
				password_confirmation_token: user.password_confirmation_token,
				old_email: user.old_email,
				new_email: user.new_email,
				new_password: user.new_password,
				used_storage: user.used_storage.nil? ? 0 : user.used_storage,
				last_active: user.last_active,
				stripe_customer_id: user.stripe_customer_id,
				plan: user.plan,
				subscription_status: user.subscription_status,
				period_end: user.period_end,
				created_at: user.created_at,
				updated_at: user.updated_at
			)

			if created
				user.destroy!
			else
				puts "Error in migrating User"
				break
			end
		end
	end

	task migrate_devs: :environment do
		Dev.all.each do |dev|
			next if DevMigration.exists?(id: dev.id)

			created = DevMigration.create(
				id: dev.id,
				user_id: dev.user_id,
				api_key: dev.api_key,
				secret_key: dev.secret_key,
				uuid: dev.uuid,
				created_at: dev.created_at,
				updated_at: dev.updated_at
			)

			if created
				dev.destroy!
			else
				puts "Error in migrating Dev"
				break
			end
		end
	end

	task migrate_apps: :environment do
		App.all.each do |app|
			next if AppMigration.exists?(id: app.id)

			created = AppMigration.create(
				id: app.id,
				dev_id: app.dev_id,
				name: app.name,
				description: app.description,
				published: app.published,
				web_link: app.link_web,
				google_play_link: app.link_play,
				microsoft_store_link: app.link_windows,
				created_at: app.created_at,
				updated_at: app.updated_at
			)

			if created
				app.destroy!
			else
				puts "Error in migrating App"
				break
			end
		end
	end

	task migrate_sessions: :environment do
		Session.all.each do |session|
			next if SessionMigration.exists?(id: session.id)
			user = UserDelegate.find_by(id: session.user_id)

			payload = {
				email: user.email,
				user_id: user.id,
				dev_id: session.app.dev.id,
				exp: session.exp.to_i
			}
			token = JWT.encode(payload, session.secret, ENV['JWT_ALGORITHM'])

			created = SessionMigration.create(
				id: session.id,
				user_id: session.user_id,
				app_id: session.app_id,
				token: "#{token}.#{session.id}",
				old_token: nil,
				device_name: session.device_name,
				device_type: session.device_type,
				device_os: session.device_os,
				created_at: session.created_at,
				secret: session.secret,
				exp: session.exp
			)

			if created
				session.destroy!
			else
				puts "Error in migrating Session"
				break
			end
		end
	end

	task migrate_tables: :environment do
		Table.all.each do |table|
			next if TableMigration.exists?(id: table.id)

			created = TableMigration.create(
				id: table.id,
				app_id: table.app_id,
				name: table.name,
				created_at: table.created_at,
				updated_at: table.updated_at
			)

			if created
				table.destroy!
			else
				puts "Error in migrating Table"
				break
			end
		end
	end

	task migrate_property_types: :environment do
		PropertyType.all.each do |type|
			next if PropertyTypeMigration.exists?(id: type.id)

			created = PropertyTypeMigration.create(
				id: type.id,
				table_id: type.table_id,
				name: type.name,
				data_type: type.data_type
			)

			if created
				type.destroy!
			else
				puts "Error in migrating PropertyType"
				break
			end
		end
	end

	task migrate_table_objects: :environment do
		TableObject.all.limit(1000).each do |obj|
			next if TableObjectMigration.exists?(id: obj.id)

			created = TableObjectMigration.create(
				id: obj.id,
				user_id: obj.user_id,
				table_id: obj.table_id,
				uuid: obj.uuid,
				file: obj.file,
				etag: obj.etag,
				created_at: obj.created_at,
				updated_at: obj.updated_at
			)

			if created
				obj.destroy!
			else
				puts "Error in migrating TableObject"
				break
			end
		end
	end

	task migrate_properties: :environment do
		Property.all.limit(1000).each do |prop|
			next if PropertyMigration.exists?(id: prop.id)

			created = PropertyMigration.create(
				id: prop.id,
				table_object_id: prop.table_object_id,
				name: prop.name,
				value: prop.value
			)

			if created
				prop.destroy!
			else
				puts "Error in migrating Property"
				break
			end
		end
	end

	task migrate_active_users: :environment do
		ActiveUser.all.each do |active_user|
			next if ActiveUserMigration.exists?(id: active_user.id)

			created = ActiveUserMigration.create(
				id: active_user.id,
				time: active_user.time,
				count_daily: active_user.count_daily,
				count_monthly: active_user.count_monthly,
				count_yearly: active_user.count_yearly
			)

			if created
				active_user.destroy!
			else
				puts "Error in migrating ActiveUser"
				break
			end
		end
	end

	task migrate_active_app_users: :environment do
		ActiveAppUser.all.each do |active_app_user|
			next if ActiveAppUserMigration.exists?(id: active_app_user.id)

			created = ActiveAppUserMigration.create(
				id: active_app_user.id,
				app_id: active_app_user.app_id,
				time: active_app_user.time,
				count_daily: active_app_user.count_daily,
				count_monthly: active_app_user.count_monthly,
				count_yearly: active_app_user.count_yearly
			)

			if created
				active_app_user.destroy!
			else
				puts "Error in migrating ActiveAppUser"
				break
			end
		end
	end

	task migrate_collections: :environment do
		Collection.all.each do |collection|
			next if CollectionMigration.exists?(id: collection.id)

			created = CollectionMigration.create(
				id: collection.id,
				table_id: collection.table_id,
				name: collection.name,
				created_at: collection.created_at,
				updated_at: collection.updated_at
			)

			if created
				collection.destroy!
			else
				puts "Error in migrating Collection"
				break
			end
		end
	end

	task migrate_notifications: :environment do
		Notification.all.each do |notification|
			next if NotificationMigration.exists?(id: notification.id)

			title_props = notification.notification_properties.where(name: "title")
			title = title_props.length > 0 ? title_props.first.value : ""
			message_props = notification.notification_properties.where(name: "message")
			message = message_props.length > 0 ? message_props.first.value : ""

			created = NotificationMigration.create(
				id: notification.id,
				user_id: notification.user_id,
				app_id: notification.app_id,
				uuid: notification.uuid,
				time: notification.time,
				interval: notification.interval,
				title: title,
				body: message
			)

			if created
				notification.destroy!
			else
				puts "Error in migrating Notification"
				break
			end
		end
	end

	task migrate_providers: :environment do
		Provider.all.each do |provider|
			next if ProviderMigration.exists?(id: provider.id)

			created = ProviderMigration.create(
				id: provider.id,
				user_id: provider.user_id,
				stripe_account_id: provider.stripe_account_id,
				created_at: provider.created_at,
				updated_at: provider.updated_at
			)

			if created
				provider.destroy!
			else
				puts "Error in migrating Provider"
				break
			end
		end
	end

	task migrate_purchases: :environment do
		Purchase.all.each do |purchase|
			next if PurchaseMigration.exists?(id: purchase.id)

			created = PurchaseMigration.create(
				id: purchase.id,
				user_id: purchase.user_id,
				table_object_id: purchase.table_object_id,
				payment_intent_id: purchase.payment_intent_id,
				provider_name: purchase.provider_name,
				provider_image: purchase.provider_image,
				product_name: purchase.product_name,
				product_image: purchase.product_image,
				price: purchase.price,
				currency: purchase.currency,
				completed: purchase.completed,
				created_at: purchase.created_at,
				updated_at: purchase.updated_at
			)

			if created
				purchase.destroy!
			else
				puts "Error in migrating Purchase"
				break
			end
		end
	end

	task migrate_table_object_collections: :environment do
		TableObjectCollection.all.each do |obj_collection|
			next if TableObjectCollectionMigration.exists?(id: obj_collection.id)

			created = TableObjectCollectionMigration.create(
				id: obj_collection.id,
				table_object_id: obj_collection.table_object_id,
				collection_id: obj_collection.collection_id,
				created_at: obj_collection.created_at
			)

			if created
				obj_collection.destroy!
			else
				puts "Error in migrating TableObjectCollection"
				break
			end
		end
	end

	task migrate_table_object_user_accesses: :environment do
		TableObjectUserAccess.all.each do |access|
			next if TableObjectUserAccessMigration.exists?(id: access.id)

			created = TableObjectUserAccessMigration.create(
				id: access.id,
				user_id: access.user_id,
				table_object_id: access.table_object_id,
				table_alias: access.table_alias,
				created_at: access.created_at
			)

			if created
				access.destroy!
			else
				puts "Error in migrating TableObjectUserAccess"
				break
			end
		end
	end

	task migrate_users_apps: :environment do
		UsersApp.all.each do |users_app|
			next if UsersAppMigration.exists?(id: users_app.id)

			created = UsersAppMigration.create(
				id: users_app.id,
				user_id: users_app.user_id,
				app_id: users_app.app_id,
				used_storage: users_app.used_storage,
				last_active: users_app.last_active,
				created_at: users_app.created_at,
				updated_at: users_app.updated_at
			)

			if created
				users_app.destroy!
			else
				puts "Error in migrating UsersApp"
				break
			end
		end
	end

	task migrate_apis: :environment do
		Api.all.each do |api|
			next if ApiMigration.exists?(id: api.id)

			created = ApiMigration.create(
				id: api.id,
				app_id: api.app_id,
				name: api.name
			)

			if created
				api.destroy!
			else
				puts "Error in migrating Api"
				break
			end
		end
	end

	task migrate_api_endpoints: :environment do
		ApiEndpoint.all.each do |api_endpoint|
			next if ApiEndpointMigration.exists?(id: api_endpoint.id)

			created = ApiEndpointMigration.create(
				id: api_endpoint.id,
				api_id: api_endpoint.api_id,
				path: api_endpoint.path,
				method: api_endpoint.method,
				commands: api_endpoint.commands,
				caching: api_endpoint.caching
			)

			if created
				api_endpoint.destroy!
			else
				puts "Error in migrating ApiEndpoint"
				break
			end
		end
	end

	task migrate_api_functions: :environment do
		ApiFunction.all.each do |api_function|
			next if ApiFunctionMigration.exists?(id: api_function.id)

			created = ApiFunctionMigration.create(
				id: api_function.id,
				api_id: api_function.api_id,
				name: api_function.name,
				params: api_function.params,
				commands: api_function.commands
			)

			if created
				api_function.destroy!
			else
				puts "Error in migrating ApiFunction"
				break
			end
		end
	end

	task migrate_api_errors: :environment do
		ApiError.all.each do |api_error|
			next if ApiErrorMigration.exists?(id: api_error.id)

			created = ApiErrorMigration.create(
				id: api_error.id,
				api_id: api_error.api_id,
				code: api_error.code,
				message: api_error.message
			)

			if created
				api_error.destroy!
			else
				puts "Error in migrating ApiError"
				break
			end
		end
	end

	task migrate_api_env_vars: :environment do
		ApiEnvVar.all.each do |api_env_var|
			next if ApiEnvVarMigration.exists?(id: api_env_var.id)

			created = ApiEnvVarMigration.create(
				id: api_env_var.id,
				api_id: api_env_var.api_id,
				name: api_env_var.name,
				value: api_env_var.value,
				class_name: api_env_var.class_name
			)

			if created
				api_env_var.destroy!
			else
				puts "Error in migrating ApiEnvVar"
				break
			end
		end
	end
end
