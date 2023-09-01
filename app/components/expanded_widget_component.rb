class ExpandedWidgetComponent < ViewComponent::Base
  def initialize(widget:, modal_heading: nil, preview_mode: nil)
    @widget = widget
    @modal_heading = modal_heading || widget.name
    @preview_mode = preview_mode
  end
end
