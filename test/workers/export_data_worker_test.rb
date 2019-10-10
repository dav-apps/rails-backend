require 'test_helper'
require 'sidekiq/testing'

class ExportDataWorkerTest < ActiveSupport::TestCase

	setup do
      save_users_and_devs
   end

  	test "ExportDataWorker will be invoked" do
		Sidekiq::Testing.fake!

		matt = users(:matt)
		archive = archives(:MattsSecondArchive)
		jobs_count = ExportDataWorker.jobs.count

		ExportDataWorker.perform_async(matt.id, archive.id)
		assert_equal(ExportDataWorker.jobs.count, jobs_count+1)
	end

	test "The zip file created by ExportDataWorker will include all necessary files and data" do
		Sidekiq::Testing.inline!

		archive = archives(:MattsSecondArchive)
		archive.name = "dav-export-#{archive.id}.zip"
		archive.save

		matt = users(:matt)
		export_data_folder_path = "/tmp/exportDataTest/"
		zip_file_content_folder_path = export_data_folder_path + "content/"
		zip_file_path = export_data_folder_path + archive.name

		ExportDataWorker.perform_async(matt.id, archive.id)

		# Get the archive from the blob storage
		FileUtils.rm_rf(Dir.glob(export_data_folder_path)) if File.exists?(export_data_folder_path)
		Dir.mkdir(export_data_folder_path) unless File.exists?(export_data_folder_path)
		Dir.mkdir(zip_file_content_folder_path) unless File.exists?(zip_file_content_folder_path)

		File.write(zip_file_path, BlobOperationsService.download_archive(archive.name)[1], encoding: 'ascii-8bit')
		extract_zip(zip_file_path, zip_file_content_folder_path)

		# Check the content of the archive
		assert(File.exists?(zip_file_content_folder_path + "data"))
		assert(File.exists?(zip_file_content_folder_path + "data/data.json"))
		assert(File.exists?(zip_file_content_folder_path + "files"))
		assert(File.exists?(zip_file_content_folder_path + "files/avatar.png"))
		assert(File.exists?(zip_file_content_folder_path + "source"))
		assert(File.exists?(zip_file_content_folder_path + "source/bootstrap.min.js"))
		assert(File.exists?(zip_file_content_folder_path + "source/bootstrap.min.css"))
		assert(File.exists?(zip_file_content_folder_path + "source/jquery.slim.min.js"))
		assert(File.exists?(zip_file_content_folder_path + "index.html"))

		# Check if the json file is complete
		json = JSON.parse(File.read(zip_file_content_folder_path + "data/data.json"))
		assert_not_nil(json["user"])
		assert_not_nil(json["user"]["email"])
		assert_not_nil(json["user"]["username"])
		assert_not_nil(json["user"]["plan"])
		assert_not_nil(json["user"]["created_at"])
		assert_not_nil(json["user"]["updated_at"])

		assert_not_nil(json["apps"])
		assert_equal(json["apps"][0]["id"], matt.apps.first.id)
		assert_equal(json["apps"][0]["name"], matt.apps.first.name)
		assert_not_nil(json["apps"][0]["tables"][0])
		assert_equal(json["apps"][0]["tables"][0]["id"], matt.apps.first.tables.first.id)
		assert_equal(json["apps"][0]["tables"][0]["name"], matt.apps.first.tables.first.name)
		assert_equal(json["apps"][0]["tables"][0]["table_objects"][0]["id"], matt.table_objects.first.id)

		# Delete the archive from the blob storage
		FileUtils.rm_rf(Dir.glob(export_data_folder_path)) if File.exists?(export_data_folder_path)
	end

	test "ExportDataWorker will split the archive to multiple parts and create archive_parts" do
		Sidekiq::Testing.inline!

		archive = archives(:MattsSecondArchive)
		archive.name = "dav-export-#{archive.id}.zip"
		archive.save

		matt = users(:matt)
		table = tables(:card)
		archive_part_name = "dav-export-#{archive.id}-files-1.zip"

		# Create table objects with files
		obj1 = TableObject.new(table_id: table.id, user_id: matt.id, file: true, uuid: SecureRandom.uuid)
		assert obj1.save
		BlobOperationsService.upload_blob(table.app_id, obj1.id, "#{Rails.root}/test/fixtures/files/test.png")
		prop1 = Property.new(table_object_id: obj1.id, name: "ext", value: "png")
		assert prop1.save

		obj2 = TableObject.new(table_id: table.id, user_id: matt.id, file: true, uuid: SecureRandom.uuid)
		assert obj2.save
		BlobOperationsService.upload_blob(table.app_id, obj1.id, "#{Rails.root}/test/fixtures/files/test3.gif")
		prop2 = Property.new(table_object_id: obj2.id, name: "ext", value: "gif")
		assert prop2.save

		# Create the archive
		ExportDataWorker.perform_async(matt.id, archive.id, 1)

		# Try to download the archive part
		assert_not_nil(BlobOperationsService.download_archive(archive_part_name))

		# Tidy up
		obj1.destroy!
		obj2.destroy!
		BlobOperationsService.delete_archive(archive.name)
		BlobOperationsService.delete_archive(archive_part_name)
		archive.destroy!
	end
end
