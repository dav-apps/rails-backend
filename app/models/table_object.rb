class TableObject < ApplicationRecord
   belongs_to :table
	belongs_to :user
   has_many :properties
   validates :uuid, presence: true
   has_many :table_objects_access_token
	has_many :access_tokens, through: :table_objects_access_token
	has_many :table_objects_provider
	has_many :providers, through: :table_objects_provider
	has_many :table_object_user_access
	has_many :table_object_collections
	has_many :collections, through: :table_object_collections
	has_many :purchases
end