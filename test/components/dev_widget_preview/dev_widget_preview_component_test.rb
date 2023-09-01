# frozen_string_literal: true

require "test_helper"

class DevWidgetPreviewComponentTest < ViewComponent::TestCase
  def setup
    # setup any necessary state here
  end

  def test_component_renders_expanded_mode
    with_request_url "/component/dev_widget_preview/12345?widget_name=Test+Widget&description=My+widget+description&mode=expanded&url=https://example.com/{MLS_NUMBER}/{NRDS_NUMBER}/{FULL_NAME}?expanded" do
      render_inline(DevWidgetPreview::DevWidgetPreviewComponent.new)
      assert_selector "header", text: "Test Widget"
      assert_selector("iframe[src='https://example.com/123456/123456789/Jane+Doe?expanded']")
    end
  end

  def test_component_renders_library_mode
    with_request_url "/component/dev_widget_preview/12345?widget_name=Test+Widget&description=My+widget+description&mode=library&url=https://example.com/111111/111111111/Test%20User" do
      rendered = render_inline(DevWidgetPreview::DevWidgetPreviewComponent.new)
      assert_selector "[data-testid='library-tile']", text: "My widget description"
      assert_match(/iframe src="https:\/\/example.com\/111111\/111111111\/Test%20User"/, rendered.to_html)
    end
  end

  def test_component_renders_inline_mode
    with_request_url "/component/dev_widget_preview/12345?widget_name=Test+Widget&description=My+widget+description&mode=inline&url=https://example.com/{MLS_NUMBER}/{NRDS_NUMBER}/{FULL_NAME}" do
      render_inline(DevWidgetPreview::DevWidgetPreviewComponent.new)
      assert_selector "header", text: "Test Widget"
      assert_selector("iframe[src='https://example.com/123456/123456789/Jane+Doe']")
    end
  end
end
