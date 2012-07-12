class Volunteer < ActiveRecord::Base
  belongs_to :transport_type
  has_many :assignments
  has_many :regions, :through => :assignments

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # column-level restrictions
  def admin_notes_authorized?
    current_user.admin
  end

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

  def super_admin?
    current_user.admin
  end
  def region_admin?(r=nil)
    current_user.assignments.each{ |a|
      return true if (a.admin and r.nil?) or (a.admin and r == a.region)
    }
    return false
  end
  def any_admin?
    self.super_admin? or self.region_admin?
  end

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :admin_notes, :email, :gone_until, :has_car, :is_disabled, :name, :on_email_list, :phone, :pickup_prefs, :preferred_contact, :transport
end
