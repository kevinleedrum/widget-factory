class InlineWidgetComponent < ViewComponent::Base
  def initialize(widget:, expand_url: nil, preview_mode: nil, error: nil)
    @widget = widget
    @expand_url = expand_url
    @preview_mode = preview_mode
    @error = error
  end
end
