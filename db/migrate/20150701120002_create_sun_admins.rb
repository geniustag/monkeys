class CreateSunAdmins < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password_digest

      t.timestamps null: false
    end

    create_table :roles do |t|
      t.string :name
      t.string :name_en
      t.string :desc

      t.timestamps null: false
    end

    create_table :resources do |t|
      t.string :name
      t.string :url
      t.integer :parent_id
      t.string :desc

      t.timestamps null: false
    end

    create_table :resources_roles do |t|
      t.integer :resource_id
      t.integer :role_id
      t.timestamps null: false
    end

    create_table :roles_users do |t|
      t.integer :user_id
      t.integer :role_id
      t.timestamps null: false
    end
  end
end

