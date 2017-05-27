class Deck < ActiveRecord::Base
    belongs_to :user
    has_many :cards, dependent: :destroy
    validates :name, presence: true, length: {minimum: 2, maximum: 20}
    validates :user_id, presence: true
end