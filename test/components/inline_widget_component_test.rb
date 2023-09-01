# frozen_string_literal: true

require "test_helper"

class InlineWidgetComponentTest < ViewComponent::TestCase
  def setup
    @widget = Widget.new(
      name: "Test Widget",
      component: "test_widget",
      partner: "MoxiWorks",
      logo_link_url: "https://moxiworks.com"
    )
    @widget.logo.attach(io: File.open(Rails.root.join("test", "fixtures", "files", "logo.png")), filename: "logo.png", content_type: "image/png")
    @error = nil
  end

  def test_component_renders_content
    render_inline(InlineWidgetComponent.new(widget: @widget)) { "Content" }
    assert_text "Content"
  end

  def test_component_renders_name
    render_inline(InlineWidgetComponent.new(widget: @widget))
    assert_selector "header", text: @widget[:name]
  end

  def test_component_renders_logo
    render_inline(InlineWidgetComponent.new(widget: @widget))
    assert_selector("img#logo[src*='logo.png'][alt='#{@widget[:partner]}']")
  end

  def test_component_render_logo_link
    render_inline(InlineWidgetComponent.new(widget: @widget))
    assert_selector("a[href='#{@widget[:logo_link_url]}']")
  end

  def test_component_renders_error
    render_inline(InlineWidgetComponent.new(widget: @widget, error: "unknown error"))
    assert_text "working on fixing things"
  end

  def test_component_renders_error_with_api
    render_inline(InlineWidgetComponent.new(widget: @widget, error: "unknown error"))
    instance_variable_set(:@error_with_api, true) do
      assert_text "trouble connecting to #{@widget[:partner]}}"
    end
  end

  def test_component_renders_expand_button
    expand_button = "button[aria-label='Expand widget']"
    render_inline(InlineWidgetComponent.new(widget: @widget))
    assert_no_selector expand_button
    render_inline(InlineWidgetComponent.new(widget: @widget, expand_url: "https://moxiworks.com"))
    assert_selector expand_button
  end

  def test_component_preview_mode
    render_inline(InlineWidgetComponent.new(widget: @widget, preview_mode: "noninteractive", expand_url: "https://moxiworks.com"))
    assert_selector "div.#{@widget[:component]}.pointer-events-none[inert]"
    assert_no_selector "a"
    assert_no_selector "button"
  end
end
