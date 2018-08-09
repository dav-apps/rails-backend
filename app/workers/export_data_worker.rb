class ExportDataWorker
	include Sidekiq::Worker

	def perform(user_id, archive_id)
		user = User.find_by_id(user_id)
		archive = Archive.find_by_id(archive_id)

		if user && archive
			root_hash = Hash.new

			# Get the user data
			user_data = Hash.new
			user_data["email"] = user.email
			user_data["username"] = user.username
			user_data["new_email"] = user.new_email
			user_data["old_email"] = user.old_email
			user_data["plan"] = user.plan
			user_data["created_at"] = user.created_at
			user_data["updated_at"] = user.updated_at

			root_hash["user"] = user_data

			apps_array = Array.new
			files_array = Array.new		# Contains the info of the file in the form of a hash with ext and uuid

			# Loop through all apps of the user
			user.apps.each do |app|
				app_hash = Hash.new
				table_array = Array.new

				app_hash["id"] = app.id
				app_hash["name"] = app.name

				# Loop through all tables of each app
				app.tables.each do |table|
					table_hash = Hash.new
					object_array = Array.new

					table_hash["id"] = table.id
					table_hash["name"] = table.name

					# Find all table_objects of the user in the table
					table.table_objects.where(user_id: user.id).each do |obj|
						object_hash = Hash.new
						property_hash = Hash.new

						object_hash["id"] = obj.id
						object_hash["uuid"] = obj.uuid
						object_hash["visibility"] = obj.visibility # TODO: Change to string
						object_hash["file"] = obj.file

						# If the object is a file, save the info for later
						if obj.file && obj.properties.where(name: "ext").count > 0
							file_object = Hash.new
							file_object["ext"] = obj.properties.where(name: "ext").first.value
							file_object["id"] = obj.id
							file_object["app_id"] = app.id
							files_array.push(file_object)
						end

						# Get the properties of the table_object
						obj.properties.each do |prop|
							property_hash[prop.name] = prop.value
						end

						object_hash["properties"] = property_hash
						object_array.push(object_hash)
					end

					table_hash["table_objects"] = object_array
					table_array.push(table_hash)
				end

				app_hash["tables"] = table_array
				apps_array.push(app_hash)
			end

			root_hash["apps"] = apps_array

			max_zip_file_bytes = 100000000	# 100 MB
			archive_temp_folder_name = "archive-#{archive.id}"
			first_archive_name = "1-#{archive.name}"
			uploaded_files = Array.new

			# Directories
			temp_path = "#{Rails.root}/tmp/"
			archive_temp_path = temp_path + archive_temp_folder_name + "/"
			files_temp_path = archive_temp_path + "files/"
			data_temp_path = archive_temp_path + "data/"
			source_temp_path = archive_temp_path + "source/"

			# Files
			avatar_file_path = files_temp_path + "avatar.png"
			data_json_file_path = data_temp_path + "data.json"
			first_zip_file_path = archive_temp_path + first_archive_name
			zip_file_path = archive_temp_path + archive.name

			Dir.mkdir(temp_path) unless File.exists?(temp_path)
			Dir.mkdir(archive_temp_path) unless File.exists?(archive_temp_path)
			Dir.mkdir(files_temp_path) unless File.exists?(files_temp_path)
			Dir.mkdir(data_temp_path) unless File.exists?(data_temp_path)
			Dir.mkdir(source_temp_path) unless File.exists?(source_temp_path)
			# /tmp/avatar-1/
				# files/
					# avatar.png
				# data/
					# data.json
				# source
					# bootstrap.min.css
					# bootstrap.min.js
					# jquery.slim.min.js
				# index.html

			# Download the avatar
			avatar = BlobOperationsService.get_avatar_information(user_id)
			File.open(avatar_file_path, 'wb') do |file|
				file.write(open(avatar[0]).read)
			end

			# Create the data.json file
			File.open(data_json_file_path, "w") { |f| f.write(root_hash.to_json) }

			# Copy the contents of the source folder
			FileUtils.cp_r(Rails.root + "lib/dav-export/source/", archive_temp_path)

			# Copy the index.html
			FileUtils.cp(Rails.root + "lib/dav-export/index.html", archive_temp_path)

			# Create the zip file of the folder
			command = "$(cd #{archive_temp_path} && zip -r #{first_archive_name} *)"
			pid = spawn(command)
			Process.wait pid

			# Delete the data folder
			FileUtils.rm_rf(Dir.glob(data_temp_path))

			# Delete the source folder
			FileUtils.rm_rf(Dir.glob(source_temp_path))

			# Delete the index.html
			index_file_path = archive_temp_path + "index.html"
			File.delete(index_file_path) if File.exists?(index_file_path)

			# Delete the avatar
			File.delete(avatar_file_path) if File.exists?(avatar_file_path)

			# Download the files
			files_array.each do |file|
				BlobOperationsService.download_blob(file["app_id"], file["id"], file["ext"], files_temp_path)
				Dir.entries(files_temp_path).select { |f| !File.directory? f }.each do |filename|
					# Add the file to the zip file
					command = "$(cd #{archive_temp_path} && zip #{first_archive_name} files/#{filename})"
					pid = spawn(command)
					Process.wait pid

					file = File.open(files_temp_path + filename)

					# Delete the file
					File.delete(file)
				end

				# Check the size of the zip file
				if File.size(first_zip_file_path) > max_zip_file_bytes
					# Split the zip into one more part
					command = "$(cd #{archive_temp_path} && zip #{first_archive_name} --out #{archive.name} -s #{max_zip_file_bytes / 1000000}m)"
					pid = spawn(command)
					Process.wait pid

					# Find the part file
					Dir.entries(archive_temp_path).select { |f| !File.directory? f }.each do |filename|
						if filename.split('.').count > 1
							file_extension = filename.split('.')[1]
							if file_extension != "zip"
								file_path = archive_temp_path + filename

								if !uploaded_files.include?(file_extension)
									# Upload the part file
									BlobOperationsService.upload_archive(file_path)
									uploaded_files.push(file_extension)
								end

								# Delete the part file
								File.delete(file_path)
							end
						end
					end
				end
			end

			
			if !File.exists?(zip_file_path)
				# Rename the first zip file
				File.rename(first_zip_file_path, zip_file_path)
			end

			# Upload the zip file
			BlobOperationsService.upload_archive(zip_file_path)

			# Delete the temp folder
			FileUtils.rm_rf(Dir.glob(archive_temp_path))

			ActiveRecord::Base.establish_connection
			archive.completed = true
			archive.save

			# Send the email
			UserNotifier.send_export_data_email(user).deliver_now
		end
	end
end
