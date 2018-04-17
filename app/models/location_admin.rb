class LocationAdmin < ActiveRecord::Base
  has_many :location_associations
  has_many :locations, through: :location_associations
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation,
                  :remember_me, :name, :region_id, :location_ids
  # attr_accessible :title, :body
end
