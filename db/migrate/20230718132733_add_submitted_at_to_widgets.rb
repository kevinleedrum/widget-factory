class AddSubmittedAtToWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :widgets, :submitted_at, :datetime
  end
end
