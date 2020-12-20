require 'test_helper'
require 'sidekiq/testing'

class DeleteUserWorkerTest < ActiveSupport::TestCase
	test "DeleteUserWorker will be invoked" do
		Sidekiq::Testing.fake!
		tester = users(:tester2)
		jobs_count = DeleteUserWorker.jobs.count

		DeleteUserWorker.perform_async(tester.id)
		assert_equal(DeleteUserWorker.jobs.count, jobs_count + 1)
	end

	test "DeleteUserWorker deletes the user and all its table objects" do
		Sidekiq::Testing.inline!
		tester = users(:tester2)
		ua = users_apps(:tester2TestApp)
		table_objects = TableObjectDelegate.where(user_id: tester.id)
		assert_equal(1, table_objects.count)

		DeleteUserWorker.perform_async(tester.id)

		ua = UsersAppDelegate.find_by(id: ua.id)
		assert_nil(ua)

		table_objects.each do |obj|
			obj = TableObjectDelegate.find_by(id: obj.id)
			assert_nil(obj)
		end
	end
end