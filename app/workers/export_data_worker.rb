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

			require 'ZipFileGenerator'
			require 'open-uri'

			# Create the necessary export directories
			archiveTempFolder = "/tmp/archives/"
			Dir.mkdir(archiveTempFolder) unless File.exists?(archiveTempFolder)

			exportZipFilePath = archiveTempFolder + archive.name
			exportFolderPath = archiveTempFolder + "#{archive.name.split(".")[0]}/"
			filesExportFolderPath = exportFolderPath + "files/"
			dataExportFolderPath = exportFolderPath + "data/"
			sourceExportFolderPath = exportFolderPath + "source/"

			# Delete the old zip file and the folder
			FileUtils.rm_rf(Dir.glob(exportFolderPath + "*"))
			File.delete(exportZipFilePath) if File.exists?(exportZipFilePath)

			# Create the directories
			Dir.mkdir(exportFolderPath) unless File.exists?(exportFolderPath)
			Dir.mkdir(filesExportFolderPath) unless File.exists?(filesExportFolderPath)
			Dir.mkdir(dataExportFolderPath) unless File.exists?(dataExportFolderPath)
			Dir.mkdir(sourceExportFolderPath) unless File.exists?(sourceExportFolderPath)

			# Download the avatar
			avatar = BlobOperationsService.get_users_avatar(user_id)

			open(filesExportFolderPath + "avatar.png", 'wb') do |file|
				file << open(avatar["url"]).read
			end

			# Download all files
			files_array.each do |file|
				BlobOperationsService.download_blob(file["app_id"], file["id"], file["ext"], filesExportFolderPath)
			end

			# Create the json file
			File.open(dataExportFolderPath + "data.json", "w") { |f| f.write(root_hash.to_json) }

			# Copy the contents of the source folder
			FileUtils.cp_r(Rails.root + "lib/dav-export/source/", exportFolderPath)

			# Copy the index.html
			FileUtils.cp(Rails.root + "lib/dav-export/index.html", exportFolderPath)

			# Create the zip file
			zf = ZipFileGenerator.new(exportFolderPath, exportZipFilePath)
			zf.write

			# Upload the zip file to the blob storage
			BlobOperationsService.upload_archive(exportZipFilePath)

			# Delete the zip file and the folder
			FileUtils.rm_rf(Dir.glob(exportFolderPath))
			File.delete(exportZipFilePath) if File.exists?(exportZipFilePath)

			# Send the email
			UserNotifier.send_export_data_email(user).deliver_now

			archive.completed = true
			archive.save
		end
	end
end
