class AddSubmittedByUuid < ActiveRecord::Migration[7.0]
  def change
    add_column :widgets, :submitted_by_uuid, :string
  end
end
