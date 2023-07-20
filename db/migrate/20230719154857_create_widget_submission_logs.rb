class CreateWidgetSubmissionLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :widget_submission_logs do |t|
      t.references :widget, null: false, foreign_key: true
      t.string :status
      t.text :notes
      t.string :updated_by
      t.string :logo_link_url
      t.string :external_url
      t.string :external_preview_url
      t.string :external_expanded_url
      t.timestamps
    end
  end
end
