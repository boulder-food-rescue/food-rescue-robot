class Volunteer < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # ActiveScaffold CRUD-level restrictions
  def authorized_for_update?
    current_user.admin or self.email == current_user.email
  end
  def authorized_for_create?
    current_user.admin
  end
  def authorized_for_delete?
    current_user.admin or self.email == current_user.email
  end

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :admin_notes, :email, :gone_until, :has_car, :is_disabled, :name, :on_email_list, :phone, :pickup_prefs, :preferred_contact, :transport
end
