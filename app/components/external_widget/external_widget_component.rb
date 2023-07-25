# frozen_string_literal: true

class ExternalWidget::ExternalWidgetComponent < ApplicationComponent
  include Components::ExternalWidgetHelper

  def before_render
    super
    return if @error.present?
    external_url = @widget.external_url
    external_url = @widget.external_preview_url if @library_mode && @widget.external_preview_url.present?
    submission_preview = ["unsubmitted", "review", "rejected"].include?(@widget.status)
    demo = @library_mode || submission_preview # use demo values for library or submission preview
    @iframe_url = populate_url_variables(external_url, demo)
  end
end
