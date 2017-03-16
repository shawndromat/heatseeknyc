module Regulatable
  module ClassMethods
    
  end
  
  module InstanceMethods
    def legal_hash
      reading_time_array.each_with_object({}) do |time, legal_hash|
        hour = time.hour + time_offset_in_hours
        
        if day_time_hours_include?(hour)
          legal_hash[time] = day_time_legal_requirement
        else
          legal_hash[time] = night_time_legal_requirement
        end
      end
    end

    def temps_with_legal_requirement
      temps | legal_requirement_array
    end

    def legal_requirement_array
      [day_time_legal_requirement, night_time_legal_requirement]
    end

    def day_time_legal_requirement
      68
    end

    def night_time_legal_requirement
      55
    end

    def day_time_outdoor_legal_requirement
      55
    end

    def night_time_outdoor_legal_requirement
      40
    end

    def morning_shoulder_hours
      (6..8)
    end

    def evening_shoulder_hours
      (20..22)
    end

    def day_time_temps_below_minimum?(indoor_temp, outdoor_temp)
      indoor_temp < day_time_legal_requirement &&
      (outdoor_temp == nil || outdoor_temp < day_time_outdoor_legal_requirement)
    end

    def night_time_temps_below_minimum?(indoor_temp, outdoor_temp)
      indoor_temp < night_time_legal_requirement &&
      (outdoor_temp == nil || outdoor_temp < night_time_outdoor_legal_requirement)
    end

    def day_time_temps_severely_below_minimum?(indoor_temp, outdoor_temp)
      temp_below_minimum?(indoor_temp, outdoor_temp, day_time_outdoor_legal_requirement, day_time_legal_requirement - 5)
    end

    def night_time_temps_severely_below_minimum?(indoor_temp, outdoor_temp)
      temp_below_minimum?(indoor_temp, outdoor_temp, night_time_outdoor_legal_requirement, night_time_legal_requirement - 5)
    end

    def day_time_temps_slightly_below_minimum?(indoor_temp, outdoor_temp)
      temp_below_minimum?(indoor_temp, outdoor_temp, day_time_outdoor_legal_requirement, day_time_legal_requirement - 3)
    end

    def night_time_temps_slightly_below_minimum?(indoor_temp, outdoor_temp)
      temp_below_minimum?(indoor_temp, outdoor_temp, night_time_outdoor_legal_requirement, night_time_legal_requirement - 3)
    end

    def temp_below_minimum?(indoor_temp, outdoor_temp, legal_outdoor_temp, legal_indoor_temp)
      indoor_temp <= legal_indoor_temp &&
          (outdoor_temp == nil || outdoor_temp < legal_outdoor_temp)
    end

    def in_major_violation?(datetime, indoor_temp, outdoor_temp)
      if during_the_day?(datetime)
        day_time_temps_severely_below_minimum?(indoor_temp, outdoor_temp)
      else
        night_time_temps_severely_below_minimum?(indoor_temp, outdoor_temp)
      end
    end

    def in_violation?(datetime, indoor_temp, outdoor_temp)
      if during_the_day?(datetime)
        day_time_temps_below_minimum?(indoor_temp, outdoor_temp)
      else
        night_time_temps_below_minimum?(indoor_temp, outdoor_temp)
      end
    end

    def in_consecutive_violation?(datetime, indoor_temp, outdoor_temp, sensor_id)
      if during_the_day?(datetime)
        consecutive_daytime_temps_below_minimum(datetime, indoor_temp, outdoor_temp, sensor_id)
      else
        consecutive_nighttime_temps_below_minimum(datetime, indoor_temp, outdoor_temp, sensor_id)
      end
    end

    def consecutive_daytime_temps_below_minimum(datetime, indoor_temp, outdoor_temp, sensor_id)
      return false if is_shoulder_time_or_above_daytime_minimum(datetime, indoor_temp, outdoor_temp)
      readings = previous_consecutive_readings_for_sensor(datetime, sensor_id)
      return false if readings.count < 2
      readings.each do |reading|
        return false if is_shoulder_time_or_above_daytime_minimum(reading.created_at, reading.temp, reading.outdoor_temp)
      end
      readings.update_all(violation_severity: Reading.violation_severities[:major_violation])
      true
    end

    def consecutive_nighttime_temps_below_minimum(datetime, indoor_temp, outdoor_temp, sensor_id)
      return false if is_shoulder_time_or_above_nighttime_minimum(datetime, indoor_temp, outdoor_temp)
      readings = previous_consecutive_readings_for_sensor(datetime, sensor_id)
      return false if readings.count < 2
      readings.each do |reading|
        return false if is_shoulder_time_or_above_nighttime_minimum(reading.created_at, reading.temp, reading.outdoor_temp)
      end
      readings.update_all(violation_severity: Reading.violation_severities[:major_violation])
      true
    end

    def previous_consecutive_readings_for_sensor(datetime, sensor_id)
      return [] if sensor_id == nil
      Reading.where(sensor_id: sensor_id, created_at: datetime - 2.5.hour..datetime)
    end

    def is_shoulder_time_or_above_nighttime_minimum(datetime, indoor_temp, outdoor_temp)
      is_shoulder_time?(datetime) || !night_time_temps_slightly_below_minimum?(indoor_temp, outdoor_temp)
    end

    def is_shoulder_time_or_above_daytime_minimum(datetime, indoor_temp, outdoor_temp)
      is_shoulder_time?(datetime) || !day_time_temps_slightly_below_minimum?(indoor_temp, outdoor_temp)
    end

    def is_shoulder_time?(datetime)
      morning_shoulder_hours.include?(datetime.hour) || evening_shoulder_hours.include?(datetime.hour)
    end

    def violation_count
      readings.reduce(0) do |count, r| 
        if in_violation?(r.created_at, r.temp, r.outdoor_temp)
          count + 1 
        else
          count 
        end
      end
    end
  end
  
  # def self.included(receiver)
  #   receiver.extend         ClassMethods
  #   receiver.send :include, InstanceMethods
  # end
end