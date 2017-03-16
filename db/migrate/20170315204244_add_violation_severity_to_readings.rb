class AddViolationSeverityToReadings < ActiveRecord::Migration
  def change
    add_column :readings, :violation_severity, :integer
  end
end
