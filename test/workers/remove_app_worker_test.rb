require 'test_helper'
require 'sidekiq/testing'

class RemoveAppWorkerTest < ActiveSupport::TestCase
	test "RemoveAppWorker will be invoked" do
		Sidekiq::Testing.fake!
		matt = users(:matt)
		cards = apps(:Cards)
		jobs_count = RemoveAppWorker.jobs.count

		RemoveAppWorker.perform_async(matt.id, cards.id)
		assert_equal(RemoveAppWorker.jobs.count, jobs_count + 1)
	end
	
	test "RemoveAppWorker removes table objects of app and user" do
		Sidekiq::Testing.inline!
		matt = users(:matt)
		cards = apps(:Cards)
		card_table = tables(:card)

		RemoveAppWorker.perform_async(matt.id, cards.id)

		assert_equal(TableObjectDelegate.where(user_id: matt.id, table_id: card_table.id).count, 0)
	end
end
