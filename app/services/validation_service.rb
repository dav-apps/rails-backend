class ValidationService

	def validate_name(name)
		error_code = 2111
		return !name || name.length < 1 ? {success: false, error: Array.new([error_code, get_error_message_by_error_code(error_code)]), status: 400} : {success: true}
	end

	def get_error_message_by_error_code(code)
		case code
		when 1101
			"Authentication failed"
		when 1102
			"Action not allowed"
		when 1103
			"Unknown validation error"
		when 1104
			"Content-type not supported"
		when 1105
			"User is not confirmed"
		when 1106
			"User is already confirmed"
		when 1107
			"All Apps need to be deleted"
		when 1108
			"Plan does not exist"
		when 1109
			"File extension not supported"
		when 1110
			"Not enough storage space"
		when 1111
			"File does not exist"
		when 1112
			"You can't create more than 10 archives"
		when 1113
			"Please add your payment information"
		when 1201
			"Password is incorrect"
		when 1202
			"User is not confirmed"
		when 1203
			"Password confirmation token is not correct"
		when 1204
			"Email confirmation token is not correct"
		when 1301
			"JWT expired"
		when 1302
			"JWT not valid"
		when 1303
			"JWT unknown error"
		when 2101
			"Missing field: auth"
		when 2102
			"Missing field: jwt"
		when 2103
			"Missing field: id"
		when 2104
			"Missing field: user_id"
		when 2105
			"Missing field: username"
		when 2106
			"Missing field: email"
		when 2107
			"Missing field: password"
		when 2108
			"Missing field: email_confirmation_token"
		when 2109
			"Missing field: password_confirmation_token"
		when 2110
			"Missing field: app_id"
		when 2111
			"Missing field: name"
		when 2112
			"Missing field: description"
		when 2113
			"Missing field: table_name"
		when 2114
			"Missing field: table_id"
		when 2115
			"Missing field: object_id"
		when 2116
			"Missing field: object"
		when 2117
			"Missing field: access_token"
		when 2118
			"Missing field: api_key"
		when 2119
			"Missing field: archive_id"
		when 2120
			"Missing field: payment_token"
		when 2201
			"Field too short: username"
		when 2202
			"Field too short: password"
		when 2203
			"Field too short: name"
		when 2204
			"Field too short: description"
		when 2205
			"Field too short: table_name"
		when 2206
			"Field too short: Property.name"
		when 2207
			"Field too short: Property.value"
		when 2301
			"Field too long: username"
		when 2302
			"Field too long: password"
		when 2303
			"Field too long: name"
		when 2304
			"Field too long: description"
		when 2305
			"Field too long: table_name"
		when 2306
			"Field too long: Property.name"
		when 2307
			"Field too long: Property.value"
		when 2401
			"Field not valid: email"
		when 2402
			"Field not valid: link_web"
		when 2403
			"Field not valid: link_play"
		when 2404
			"Field not valid: link_windows"
		when 2405
			"Field not valid: payment_token"
		when 2501
			"Field contains not allowed characters: table_name"
		when 2601
			"Field is empty: new_email"
		when 2602
			"Field is empty: old_email"
		when 2603
			"Field is empty: new_password"
		when 2701
			"Field already taken: username"
		when 2702
			"Field already taken: email"
		when 2703
			"Field already taken: name"
		when 2704
			"Field already taken: uuid"
		when 2801
			"Resource does not exist: User"
		when 2802
			"Resource does not exist: Dev"
		when 2803
			"Resource does not exist: App"
		when 2804
			"Resource does not exist: Table"
		when 2805
			"Resource does not exist: TableObject"
		when 2806
			"Resource does not exist: Property"
		when 2807
			"Resource does not exist: Event"
		when 2808
			"Resource does not exist: EventLog"
		when 2809
			"Resource does not exist: AccessToken"
		when 2810
			"Resource does not exist: Archive"
		when 2901
			"Resource already exists: User"
		when 2902
			"Resource already exists: Dev"
		when 2903
			"Resource already exists: App"
		when 2904
			"Resource already exists: Table"
		when 2905
			"Resource already exists: TableObject"
		when 2906
			"Resource already exists: Property"
		when 2907
			"Resource already exists: Event"
		when 2908
			"Resource already exists: EventLog"
		when 2909
			"Resource already exists: AccessToken"
		else
			raise("The error code #{code} does not exist!")
		end
	end
end