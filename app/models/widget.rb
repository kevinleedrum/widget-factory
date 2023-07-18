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
  after_create :set_external_component
  after_save :purge_logo, if: :remove_logo

  has_many :user_widgets, dependent: :destroy

  scope :activated_widgets, -> {
    where(status: Widget.statuses[:ready], activation_date: ..Time.zone.now)
      .or(where(status: Widget.statuses[:ready], activation_date: nil))
  }

  validates :name, presence: true

  def as_json(options = {})
    options[:methods] = [:activated, :logo_url]
    super
  end

  def activated
    status == Widget.statuses[:ready] && (activation_date.blank? || activation_date <= Time.zone.now)
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

  private

  def set_submitted_at
    self.submitted_at = Time.zone.now
  end

  def set_external_component
    if component.blank? && external_url.present?
      update_column(:component, "external_#{id}")
    end
  end

  def purge_logo
    logo.purge_later
  end
end
