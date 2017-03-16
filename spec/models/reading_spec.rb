require 'spec_helper'

describe Reading do

  it "has a temperature" do
    reading = create(:reading, temp: 64)
    expect(reading.temp).to eq(64)
  end

  it "has a timestamp" do
    reading = create(:reading)
    expect(reading.created_at).to be_an_instance_of(ActiveSupport::TimeWithZone)
  end

  it "cannot be created without a temperature" do
    tom = create(:user)
    twine1 = create(:twine)
    reading = Reading.create(user: tom, twine: twine1)
    expect(reading.persisted?).to eq false
  end

  it "cannot be created without a user" do
    temp = 53
    twine1 = create(:twine)
    reading = Reading.create(temp: temp, twine: twine1)
    expect(reading.persisted?).to eq false
  end

  describe "sets major violations" do
    context "during the day" do
      it "sets reading 5+ degrees below minimum as major violation" do
        daytime = Time.parse('March 1, 2015 12:00:00')
        reading = create(:reading, temp: 63, outdoor_temp: 54, created_at: daytime)

        expect(reading.violation_severity).to eq "major_violation"
        expect(reading.violation?).to eq true
      end
    end

    context "during the night" do
      it "sets reading 5+ degrees below minimum as major violation" do
        nighttime = Time.parse('March 1, 2015 1:00:00')
        reading = create(:reading, temp: 50, outdoor_temp: 39, created_at: nighttime)

        expect(reading.violation_severity).to eq "major_violation"
        expect(reading.violation?).to eq true
      end
    end
  end

  describe "sets minor violations" do
    context "during the day" do
      it "sets reading less than 5 degrees below minimum (but still below) as violation (minor)" do
        daytime = Time.parse('March 1, 2015 12:00:00')
        reading = create(:reading, temp: 64, outdoor_temp: 54, created_at: daytime)

        expect(reading.violation_severity).to eq "minor_violation"
        expect(reading.violation?).to eq true
      end
    end

    context "during the night" do
      it "sets reading less than 5 degrees below minimum (but still below) as violation (minor)" do
        nighttime = Time.parse('March 1, 2015 1:00:00')
        reading = create(:reading, temp: 51, outdoor_temp: 39, created_at: nighttime)

        expect(reading.violation_severity).to eq "minor_violation"
        expect(reading.violation?).to eq true
      end
    end
  end

  describe "consecutive violations" do
    context "during midday" do
      it "sets three major violations when three consecutive readings are 3 degrees below requirement" do
        time = Time.parse('March 1, 2015 15:00:00')

        reading1 = create(:reading, temp: 65, outdoor_temp: 39, created_at: time - 2.hour, sensor_id: 1)
        expect(reading1.violation?).to eq true
        expect(reading1.violation_severity).to eq "minor_violation"

        reading2 = create(:reading, temp: 65, outdoor_temp: 39, created_at: time - 1.hour, sensor_id: 1)
        expect(reading2.violation?).to eq true
        expect(reading2.violation_severity).to eq "minor_violation"

        reading3 = create(:reading, temp: 65, outdoor_temp: 39, created_at: time, sensor_id: 1)
        expect(reading3.violation?).to eq true

        expect(reading1.reload.violation_severity).to eq "major_violation"
        expect(reading2.reload.violation_severity).to eq "major_violation"
        expect(reading3.violation_severity).to eq "major_violation"
      end
    end

    context "during night" do
      it "sets three major violations when three consecutive readings are 3 degrees below requirement" do
        time = Time.parse('March 1, 2015 1:00:00')

        reading1 = create(:reading, temp: 52, outdoor_temp: 39, created_at: time - 2.hour, sensor_id: 1)
        expect(reading1.violation?).to eq true
        expect(reading1.violation_severity).to eq "minor_violation"

        reading2 = create(:reading, temp: 52, outdoor_temp: 39, created_at: time - 1.hour, sensor_id: 1)
        expect(reading2.violation?).to eq true
        expect(reading2.violation_severity).to eq "minor_violation"

        reading3 = create(:reading, temp: 52, outdoor_temp: 39, created_at: time, sensor_id: 1)
        expect(reading3.violation?).to eq true

        expect(reading1.reload.violation_severity).to eq "major_violation"
        expect(reading2.reload.violation_severity).to eq "major_violation"
        expect(reading3.violation_severity).to eq "major_violation"
      end
    end

    context "during transitional (shoulder) times" do
      it "ignores morning shoulder times when setting consecutive major violations" do
        time = Time.parse('March 1, 2015 7:00:00')

        reading1 = create(:reading, temp: 52, outdoor_temp: 39, created_at: time - 2.hour, sensor_id: 1)
        expect(reading1.violation?).to eq true
        expect(reading1.violation_severity).to eq "minor_violation"

        reading2 = create(:reading, temp: 65, outdoor_temp: 39, created_at: time - 1.hour, sensor_id: 1)
        expect(reading2.violation?).to eq true
        expect(reading2.violation_severity).to eq "minor_violation"

        reading3 = create(:reading, temp: 65, outdoor_temp: 39, created_at: time, sensor_id: 1)

        expect(reading1.reload.violation_severity).to eq "minor_violation"
        expect(reading2.reload.violation_severity).to eq "minor_violation"
        expect(reading3.violation_severity).to eq "minor_violation"
        expect(reading3.violation?).to eq true
      end
    end

    it "ignores evening shoulder times when setting consecutive major violations" do
      time = Time.parse('March 1, 2015 21:00:00')

      reading1 = create(:reading, temp: 65, outdoor_temp: 39, created_at: time - 2.hour, sensor_id: 1)
      expect(reading1.violation?).to eq true
      expect(reading1.violation_severity).to eq "minor_violation"

      reading2 = create(:reading, temp: 65, outdoor_temp: 39, created_at: time - 1.hour, sensor_id: 1)
      expect(reading2.violation?).to eq true
      expect(reading2.violation_severity).to eq "minor_violation"

      reading3 = create(:reading, temp: 65, outdoor_temp: 39, created_at: time, sensor_id: 1)

      expect(reading1.reload.violation_severity).to eq "minor_violation"
      expect(reading2.reload.violation_severity).to eq "minor_violation"
      expect(reading3.violation_severity).to eq "minor_violation"
      expect(reading3.violation?).to eq true
    end
  end

  describe ".create_from_params" do
    it "rounds temperature properly" do
      allow(WeatherMan).to receive(:outdoor_temp_for).and_return(45)
      time = Time.parse('March 1, 2015 12:00:00')
      sensor = create(:sensor, name: "0013a20040c17f5a", created_at: time)
      user = create(:user)
      user.sensors << sensor

      @reading = Reading.create_from_params(
        :time =>1426064293.0,
        :temp => 56.7,
        :sensor_name => "0013a20040c17f5a",
        :verification => "c0ffee"
      )
      expect(@reading.temp).to eq 57
    end

    it "handles nil temperature properly", :vcr do
      allow(WeatherMan).to receive(:outdoor_temp_for).and_return(nil)
      user = create(:user, zip_code: '10216')
      sensor = create(:sensor, name: "abcdefgh")
      user.sensors << sensor
      params = ActionController::Parameters.new(
        "reading" => {
          "temp"=>67.42,
          "verification"=>"c0ffee",
          "time"=>1452241576.0,
          "sensor_name"=>"abcdefgh"
        }
      )
      reading = Reading.create_from_params(params[:reading])
      expect(reading.outdoor_temp).to be_nil
    end
  end
end
