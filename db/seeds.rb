# encoding: utf-8
if User.count == 0
  u = User.create(name: 'admin', email: 'admin@admin.com', password: '123456') 
  u.save(validate: false)
  Role.create(name: '超级管理员', name_en: 'admin', desc: '超级管理员')
  u.roles = Role.all
end
