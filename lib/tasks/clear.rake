namespace :clear do
  task account_versions: :environment do
    items = %w(
      account_versions
      withdraws deposits
      etransactions
      payment_transactions
    )
    puts "Start clear tables: #{items}"
    items.each { |table| ActiveRecord::Base.connection.execute("TRUNCATE #{table}") }
    Account.where('balance > 0 or locked > 0').update_all(balance: 0, locked: 0)
    puts "Clear success!"
  end
end
