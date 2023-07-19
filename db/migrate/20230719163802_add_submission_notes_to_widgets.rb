class AddSubmissionNotesToWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :widgets, :submission_notes, :text
  end
end
