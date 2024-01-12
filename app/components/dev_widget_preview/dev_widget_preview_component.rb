# frozen_string_literal: true

class DevWidgetPreview::DevWidgetPreviewComponent < ApplicationComponent
  include Components::ExternalWidgetHelper

  def before_render # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    super
    return if @error.present?
    @widget = Widget.new({
      component: "external_widget_preview",
      external_url: params["url"],
      name: params["widget_name"] || "New Widget",
      description: params["description"] || "Your description will appear here once entered.",
      partner: params["partner"] || "",
      logo_link_url: params["logo_link_url"]
    })
    @iframe_url = populate_url_variables(params["url"], true)
    token = @nucleus_api_client.get_token(params["uuid"])
    @iframe_url = sign_url(@iframe_url, token) if token
  end
end
