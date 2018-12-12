# encoding: utf-8
Member.create(name: 'admin', email: 'admin@admin.com', password: '123456') if Member.count == 0
# add withdraw data
Member.find(4).accounts.each do |ac|
  10.times do
    w=Withdraw.new(
        account_id: ac.id,
        member_id: ac.member_id,
        currency: ac.currency_obj.id,
        amount: amount = rand(ac.balance/1000),
        fee: 0.001,
        sum: amount,
        fund_uid: 'xxxxxxxxxxxxxxxxx',
    )
    w.save!
  end
end