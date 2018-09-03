class ExportDataWorker
	include Sidekiq::Worker

	def perform(user_id, archive_id, max_size_mb = 100)
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

			max_zip_file_bytes = max_size_mb * 1000000
			archive_temp_folder_name = "archive-#{archive.id}"
			files_archive_name = "#{archive.name[0..archive.name.length - 5]}-files-"

			# Directories
			temp_path = "#{Rails.root}/tmp/"
			archive_temp_path = temp_path + archive_temp_folder_name + "/"
			files_temp_path = archive_temp_path + "files/"
			data_temp_path = archive_temp_path + "data/"
			source_temp_path = archive_temp_path + "source/"

			# Files
			avatar_file_path = files_temp_path + "avatar.png"
			data_json_file_path = data_temp_path + "data.json"
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
			command = "$(cd #{archive_temp_path} && zip -r #{archive.name} *)"
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

			i = 1

			# Download the files
			files_array.each do |file|
				# Download the file
				BlobOperationsService.download_blob(file["app_id"], file["id"], file["ext"], files_temp_path)

				# If the size of the files folder is too big, create the zip file and upload it
				files_size = 0

				# Get the size of the files folder
				Dir.entries(files_temp_path).select { |f| !File.directory? f }.each do |filename|
					files_size = files_size + File.size(files_temp_path + filename)
				end

				if files_size > max_zip_file_bytes
					filename = files_archive_name + i.to_s + ".zip"
					filepath = archive_temp_path + filename

					upload_files(filename, filepath, files_temp_path, archive_temp_path, archive.id)

					i = i + 1
				end
			end

			# Upload the remaining files
			if Dir.entries(files_temp_path).select { |f| !File.directory? f }.length > 0
				filename = files_archive_name + i.to_s + ".zip"
				filepath = archive_temp_path + filename

				upload_files(filename, filepath, files_temp_path, archive_temp_path, archive.id)

				i = i + 1
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

	def upload_files(filename, filepath, files_temp_path, archive_temp_path, archive_id)
		# Create a zip file of the files folder
		command = "$(cd #{archive_temp_path} && zip #{filename} files/*)"
		pid = spawn(command)
		Process.wait pid

		# Upload the zip file
		BlobOperationsService.upload_archive(filepath)

		# Create a new archive_part object
		archive_part = ArchivePart.new(archive_id: archive_id, name: filename)
		archive_part.save

		# Delete the files
		FileUtils.rm_rf Dir.glob("#{files_temp_path}/*")

		# Delete the zip file
		File.delete(filepath)
	end
end
