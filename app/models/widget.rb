class Widget < ApplicationRecord
  enum status: {
    unsubmitted: "unsubmitted", # draft external widget
    rejected: "rejected",
    submitted: "submitted",
    review: "review", # admin has opened the widget for review
    draft: "draft", # approved, but not yet activated by admin
    ready: "ready", # activated (or will be activated if activation_date is in the future)
    deactivated: "deactivated"
  }

  has_one_attached :logo
  attribute :remove_logo, :boolean
  before_create :set_submitted_at, if: -> { status == "submitted" }
  before_update :set_submitted_at, if: -> { status_changed?(to: "submitted") }
  before_update :add_submission_log, if: -> { status_changed? }
  after_create :set_external_component
  after_create :add_submission_log
  after_update :revise_submission_log, if: -> { status == "submitted" && !status_changed? }
  after_save :purge_logo, if: :remove_logo

  belongs_to :parent_widget, class_name: "Widget", optional: true
  has_many :revisions, class_name: "Widget", foreign_key: "parent_widget_id", dependent: :destroy
  scope :parents, -> { where(parent_widget_id: nil) }

  has_many :user_widgets, dependent: :destroy
  has_many :widget_submission_logs, dependent: :destroy

  scope :activated_widgets, -> {
    where(status: Widget.statuses[:ready], activation_date: ..Time.zone.now)
      .or(where(status: Widget.statuses[:ready], activation_date: nil))
  }

  validates :name, presence: true

  def as_json(options = {})
    options[:methods] = [:activated, :logo_url]
    super
  end

  def status
    super || "unsubmitted"
  end

  def activated
    status == Widget.statuses[:ready] && (activation_date.blank? || activation_date <= Time.zone.now)
  end

  def can_destroy?
    ["unsubmitted", "rejected", "submitted"].include?(status) || (status == "draft" && parent_widget_id.present?)
  end

  def view_component
    c = component.start_with?("external") ? "external_widget" : component
    Object.const_get("#{c.camelize}::#{c.camelize}Component")
  rescue NameError
    nil
  end

  def logo_url
    return unless logo.attached?
    Rails.application.routes.url_helpers.rails_representation_url(logo, only_path: true)
  end

  def self.log_event(component, event_type, event_data = {}, user_uuid, company_uuid, board_uuid, office_uuid)
    EventLoggerJob.perform_async(
      event_type,
      component,
      event_data.to_json,
      user_uuid,
      company_uuid,
      board_uuid,
      office_uuid
    )
  end

  def create_revision
    revision = self.class.new(
      parent_widget_id: id,
      status: "unsubmitted",
      submitted_by_uuid: submitted_by_uuid,
      name: name,
      description: description,
      partner: partner,
      logo_link_url: logo_link_url,
      external_url: external_url,
      external_preview_url: external_preview_url,
      external_expanded_url: external_expanded_url
    )
    revision.logo.attach(logo.blob) if logo.attached?
    revision.save
    revision
  end

  def merge_into_parent
    parent_widget.update(
      submitted_by_uuid: submitted_by_uuid,
      name: name,
      description: description,
      partner: partner,
      logo_link_url: logo_link_url,
      external_url: external_url,
      external_preview_url: external_preview_url,
      external_expanded_url: external_expanded_url
    )
    parent_widget.logo.attach(logo.blob) if logo.attached?
    parent_widget.save
    widget_submission_logs.update_all(widget_id: parent_widget.id)
    destroy
    parent_widget
  end

  private

  def set_submitted_at
    self.submitted_at = Time.zone.now
  end

  def set_external_component
    if component.blank?
      update_column(:component, "external_#{id}")
    end
  end

  def purge_logo
    logo.purge_later
  end

  def add_submission_log
    # Do not create logs after the widget has been approved
    return if ["draft", "ready", "deactivated"].include?(status_was)
    # Do not create a log when the widget is rejected and then redrafted
    return if status == "unsubmitted" && status_was == "rejected"
    widget_submission_logs.create(
      status: status,
      notes: submission_notes,
      logo_link_url: logo_link_url,
      external_url: external_url,
      external_preview_url: external_preview_url,
      external_expanded_url: external_expanded_url,
      updated_by: updated_by
    )
    clear_notes if status_changed? && status_was == "review" # Clear admin's notes after logging approval/rejection
  end

  def revise_submission_log
    widget_submission_logs.last.update(
      notes: submission_notes,
      logo_link_url: logo_link_url,
      external_url: external_url,
      external_preview_url: external_preview_url,
      external_expanded_url: external_expanded_url,
      updated_by: updated_by
    )
  end

  def clear_notes
    self.submission_notes = nil
  end
end
