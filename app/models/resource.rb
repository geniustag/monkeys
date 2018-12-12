class Resource < ActiveRecord::Base
  has_and_belongs_to_many :roles
  validates :name, :url, presence: true

  scope :supers, -> {where(parent_id: nil)}
  scope :sub_menus, -> {where.not(parent_id: nil)}

  def parent
    Resource.find_by_id(self.parent_id)
  end

  def parent_name
    parent.try(:name)
  end

  def self.select_values(tag, obj)
     return supers.collect{|a| [a.name, a.id]} if tag.to_s == "parent_id"
     super 
  end
end
