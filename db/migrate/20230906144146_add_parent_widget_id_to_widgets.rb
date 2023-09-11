class AddParentWidgetIdToWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :widgets, :parent_widget_id, :integer
  end
end
