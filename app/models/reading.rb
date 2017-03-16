class Reading < ActiveRecord::Base
  belongs_to :twine
  belongs_to :sensor
  belongs_to :user

  enum violation_severity: [ :minor_violation, :major_violation ]

  validates :user_id, presence: true
  validates :temp, presence: true

  before_create :set_violation_boolean

  def set_violation_boolean
    time = created_at || Time.now
    self.violation = user.in_violation?(time, temp, outdoor_temp)
    if self.violation?
      self.violation_severity = "major_violation" if user.in_consecutive_violation?(time, temp, outdoor_temp, sensor_id)
      self.violation_severity = "major_violation" if user.in_major_violation?(time, temp, outdoor_temp)
      self.violation_severity = "minor_violation" unless self.major_violation?
    else
      self.violation_severity = nil
    end
    true # this method must return true
  end

  def self.new_from_twine(temp, outdoor_temp, twine, user)
    new.tap do |r|
      r.temp = temp
      r.outdoor_temp = outdoor_temp
      r.twine = twine
      r.user = user
    end
  end

  def self.find_by_params(params)
    sensor = Sensor.find_by(name: params[:sensor_name])
    user = sensor.user
    time = Time.at params[:time].to_i
    temp = params[:temp].to_f.round

    find_by(
      sensor: sensor,
      user: user,
      temp: temp,
      created_at: time
    )
  end

  def self.create_from_params(params)
    sensor = Sensor.find_by(name: params[:sensor_name])
    user = sensor.user
    time = Time.at params[:time].to_i
    temp = params[:temp].to_f.round
    outdoor_temp = WeatherMan.outdoor_temp_for(time, user.zip_code, 0.1)

    create!(
      sensor: sensor,
      user: user,
      temp: temp,
      outdoor_temp: outdoor_temp,
      created_at: time
    )
  end

  def self.verification_valid?(code)
    true #placeholder for hash algorithm
  end

end
