# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

unless User.find_by(email: "mbeirut@heatseeknyc.com")

  User.create(
    :first_name => "Jane",
    :last_name => "Doe",
    :address => "100 Fake St",
    :zip_code => "10004",
    :email => "jane@heatseeknyc.com",
    :password => '33west26'
  )

  User.create(
    :first_name => "John",
    :last_name => "Doe",
    :address => "200 Bogus Lane",
    :zip_code => "10321",
    :email => "john@heatseeknyc.com",
    :password => '33west26'
  )

  User.create(
    :first_name => "Demo User",
    :last_name => "Account",
    :address => "100 Fake St",
    :zip_code => "10004",
    :email => 'demo-user@heatseeknyc.com',
    :password => '33west26'
  )

  User.create(
    :first_name => "Demo Lawyer",
    :last_name => "Account",
    :address => "100 Fake St",
    :zip_code => "10004",
    :email => 'demo-lawyer@heatseeknyc.com',
    :password => '33west26'
  )
 
  User.create(
    :first_name => "Live Update",
    :last_name => "Account",
    :address => "200 Bogus Lane",
    :zip_code => "10321",
    :email => "live-update@heatseeknyc.com",
    :password => '33west26'
  )

  User.create(
    :first_name => "Team Member",
    :last_name => "Heatseek",
    :address => "100 Fake St",
    :zip_code => "10004",
    :email => "team-member@heatseeknyc.com",
    :password => '33west26'
  )
end

jane = User.find_by(email: "jane@heatseeknyc.com")
john = User.find_by(email: "john@heatseeknyc.com")
demo = User.find_by(email: "demo-user@heatseeknyc.com")
live = User.find_by(email: "live-update@heatseeknyc.com")
users = [jane, john, demo, live]

lawyer = User.find_by(email: "demo-lawyer@heatseeknyc.com")
lawyer.permissions = 50
lawyer.save

team_member = User.find_by(email: "team-member@heatseeknyc.com")
team_member.permissions = 10
team_member.collaborators = users
team_member.save

now = Time.now
users.each do |user|
  current_time = now - (now.to_i % 3600)
  user.readings.clear
  current_temp = 68
  current_outdoor_temp = 45
  200.times do
    current_time -= 3600
    if user.during_the_day?(current_time)
      current_temp += rand(-3..2)
      current_outdoor_temp += rand(-1..3)
    else
      current_temp += rand(-2..3)
      current_outdoor_temp += rand(-1..3)
    end

    current_temp -= 2 if current_temp > 68
    current_temp += 2 if current_temp < 52
    current_outdoor_temp -= 2 if current_outdoor_temp > 55
    current_outdoor_temp += 2 if current_outdoor_temp < 25

    user.readings << Reading.new(created_at: current_time, temp: current_temp, outdoor_temp: current_outdoor_temp, user: user, twine: user.twine)
  end
end
