class AddExternalUrlToWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :widgets, :external_url, :string
  end
end
