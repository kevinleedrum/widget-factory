class AddExternalUrlsToWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :widgets, :external_preview_url, :string # for library modal and admin form previews
    add_column :widgets, :external_expanded_url, :string
  end
end
