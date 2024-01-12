# frozen_string_literal: true

class ExternalWidget::ExternalWidgetComponent < ApplicationComponent
  include Components::ExternalWidgetHelper

  def before_render
    super
    return if @error.present?
    external_url = @widget.external_url
    external_url = @widget.external_preview_url if @preview_mode == "noninteractive" && @widget.external_preview_url.present?
    submission_preview = ["unsubmitted", "review", "rejected"].include?(@widget.status)
    demo = @preview_mode.present? || submission_preview # use demo values for library or submission preview
    @iframe_url = populate_url_variables(external_url, demo)
    token = @nucleus_api_client.get_token(@widget.submitted_by_uuid)
    @iframe_url = sign_url(@iframe_url, token) if token
    return if @widget.external_expanded_url.blank?
    @expand_url = component_named_expanded_path(@widget.component, params[:session_id])
    @expanded_iframe_url = populate_url_variables(@widget.external_expanded_url)
  end
end
