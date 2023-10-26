class AddAdminResponseToWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :widgets, :admin_response, :text
  end
end
