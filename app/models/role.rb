#encoding: utf-8
class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_and_belongs_to_many :resources

  validates :name, presence: true
  
  before_destroy :has_users
  
  def has_users
    return errors.add(self.name, "该角色有用户不能删除") && false if users.size > 0
  end
  
  def is_admin?
    self == Role.admin
  end

  def self.admin
    find(1)
  end
end
