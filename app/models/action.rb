# An action a user has triggered
class Action < ApplicationRecord
  belongs_to :user
end
