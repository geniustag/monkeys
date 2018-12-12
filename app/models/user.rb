class User < ActiveRecord::Base
  has_and_belongs_to_many :roles
  has_many :resources, through: :roles
  has_secure_password

  validates :email, :name, presence: true
  validates :email, length: 6..50, 
                    uniqueness: true,
                    format: /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\z/i
  before_destroy :admin_users
  
  def admin_users
    return true unless self.is_admin?
    errors.add(:user, "Admin Can not be delete!!")
    false
  end

  def is_admin?
    roles.include?(Role.admin) 
  end

  def role_names
    roles.map(&:name).join(",")
  end
  
  def can_access?(path)
    return true unless Resource.all.map(&:url).include?(path) 
    resources.map(&:url).include?(path)
  end
end
