class Widget < ApplicationRecord
  enum status: {ready: "ready", draft: "draft", deactivated: "deactivated"}

  has_one_attached :logo
  attribute :remove_logo, :boolean
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

  def restore!
    self.status = Widget.statuses[:draft]
    save
  end

  def activate!
    self.status = Widget.statuses[:ready]
    save
  end

  def deactivate!
    self.status = Widget.statuses[:deactivated]
    self.activation_date = nil
    save
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

  def purge_logo
    logo.purge_later
  end
end
