class Card < ActiveRecord::Base
    belongs_to :deck
    belongs_to :user
    validates :page1, presence: true, length: {minimum: 2, maximum: 25}
    validates :page2, presence: true, length: {minimum: 2, maximum: 25}
    validates :deck_id, presence: true
end