class User < ApplicationRecord
  has_many :alerts, dependent: :destroy
end
