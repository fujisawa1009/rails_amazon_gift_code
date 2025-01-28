
# 管理者アカウントの作成
administrator = Administrator.find_or_initialize_by(email: 'admin@gmail.com')
administrator.password = 'admin'
administrator.password_confirmation = 'admin'
administrator.save!

puts 'Administrator has been created successfully!'

# テストユーザーの作成
test_user = User.find_or_initialize_by(email: 'test@example.com')
test_user.password = 'test'
test_user.password_confirmation = 'test'
test_user.name = 'test'
test_user.save!

puts 'Test user has been created successfully!'

# 追加の20人のテストユーザー作成
20.times do |i|
  User.create!(
    email: "tests#{i+1}@example.com",
    password: 'password',
    password_confirmation: 'password',
    name: "Test User #{i+1}"
  )
end

puts '20 additional test users have been created successfully!'

# ギフトコードのテストデータ作成
10.times do |i|
  GiftCode.create!(
    user: test_user,
    administrator: administrator,
    unique_url: SecureRandom.hex(16),
    status: i % 3, # 0: created, 1: sent, 2: claimed を順番に設定
    creation_request_id: SecureRandom.hex(20),
    amount: [10, 20, 30, 40].sample,
    currency_code: 'JPY',
    gc_id: "GC#{SecureRandom.hex(8)}",
    claimed_at: i > 5 ? Time.current : nil,
    expires_at: 30.days.from_now
  )
end

puts 'Gift codes have been created successfully!'
