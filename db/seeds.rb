# encoding: utf-8
User.create(name: 'admin', email: 'admin@admin.com', phone: 10000000000, password: '123456') if User.count == 0
Role.create(name: '超级管理员', name_en: 'admin', desc: '超级管理员') if Role.count == 0
User.first.roles = Role.all
