# frozen_string_literal: true

require "test_helper"

class Hurdlr::HurdlrComponentTest < ViewComponent::TestCase
  def setup
    @widget = Widget.create(name: "Profit + Loss", component: "hurdlr", partner: "Hurdlr")
    @widget.logo.attach(io: File.open(Rails.root.join("test", "fixtures", "files", "logo.png")), filename: "logo.png", content_type: "image/png")
    @error = nil
  end

  def test_component_renders_metrics_table
    # Rows are added via JavaScript, so we will just check for the headers
    table = rendered.css("table").to_html
    assert_includes(table, "Metric")
    assert_includes(table, "Amount")
  end

  def test_component_renders_signup
    instance_variable_set(:@error, "subscription not found") do
      assert_includes(
        rendered.to_html,
        "Sign up for Hurdlr"
      )
    end
  end

  private

  def rendered
    render_inline(Hurdlr::HurdlrComponent.new(preview_mode: "noninteractive"))
  end
end
