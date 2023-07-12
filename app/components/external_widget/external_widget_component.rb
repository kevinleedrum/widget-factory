# frozen_string_literal: true

class ExternalWidget::ExternalWidgetComponent < ApplicationComponent
  include Components::ExternalWidgetHelper

  def before_render
    super
    return if @error.present?
    @iframe_url = populate_url_variables(@widget.external_url)
  end
end
