# frozen_string_literal: true

require "test_helper"

class ExternalWidgetComponentTest < ViewComponent::TestCase
  def setup
    @widget = Widget.new(
      name: "Test External Widget",
      status: "unsubmitted",
      component: "external_test",
      partner: "MoxiWorks",
      external_url: "https://example.com/{MLS_NUMBER}/{NRDS_NUMBER}/{FULL_NAME}",
      external_expanded_url: "https://example.com/{MLS_NUMBER}/{NRDS_NUMBER}/{FULL_NAME}?expanded",
      external_preview_url: "https://example.com/preview/{MLS_NUMBER}/{NRDS_NUMBER}/{FULL_NAME}"
    )
    @widget.logo.attach(io: File.open(Rails.root.join("test", "fixtures", "files", "logo.png")), filename: "logo.png", content_type: "image/png")
    @error = nil
  end

  def test_component_renders_submission_preview
    with_inline_component do
      render_inline(ExternalWidget::ExternalWidgetComponent.new(widget: @widget))
      assert_selector("iframe[src='https://example.com/123456/123456789/Jane+Doe']")
    end
  end

  def test_component_renders_expanded_submission_preview
    with_expanded_component do
      render_inline(ExternalWidget::ExternalWidgetComponent.new(widget: @widget))
      assert_selector("iframe[src='https://example.com/111111/111111111/Test+User?expanded']")
    end
  end

  def test_component_renders_library_preview
    with_inline_component do
      render_inline(ExternalWidget::ExternalWidgetComponent.new(widget: @widget, preview_mode: "noninteractive"))
      assert_selector("iframe[src='https://example.com/preview/123456/123456789/Jane+Doe']")
    end
  end

  def test_component_renders_live_url
    @widget.status = "ready"
    with_inline_component do
      render_inline(ExternalWidget::ExternalWidgetComponent.new(widget: @widget))
      assert_selector("iframe[src='https://example.com/111111/111111111/Test+User']")
    end
  end

  def with_inline_component
    with_request_url "/component/external_test/12345" do
      yield
    end
  end

  def with_expanded_component
    with_request_url "/component/external_test/expanded/12345" do
      yield
    end
  end
end
