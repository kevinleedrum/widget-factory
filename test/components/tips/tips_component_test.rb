# frozen_string_literal: true

require "test_helper"

class Tips::TipsComponentTest < ViewComponent::TestCase
  def setup
    @widget = Widget.create(name: "Stellar Scoop", component: "tips", partner: "Stellar")
    @widget.logo.attach(io: File.open(Rails.root.join("test", "fixtures", "files", "logo.png")), filename: "logo.png", content_type: "image/png")
    @error = nil
  end

  def test_component_renders_tip
    with_tips_params do
      assert_includes(
        rendered.css(".tip-container p").to_html,
        my_tip[:description]
      )
    end
  end

  def test_component_renders_cta
    with_tips_params do
      assert_includes(
        rendered.css("mx-button").to_html,
        my_tip[:cta_label]
      )
      assert_includes(
        rendered.css("mx-button").to_html,
        "href=\"#{my_tip[:cta_url]}\""
      )
    end
  end

  def test_component_sets_bg
    with_tips_params do
      assert_includes(
        rendered.css(".tip-bg").to_html,
        "--tip-bg-#{my_tip[:bg]}"
      )
    end
  end

  private

  def rendered
    render_inline(Tips::TipsComponent.new)
  end

  def my_tip
    {
      description: "Test tip",
      cta_label: "Test CTA",
      cta_url: "https://moxiworks.com",
      bg: "1"
    }
  end

  def with_tips_params
    q = {
      tips: my_tip
    }
    with_request_url "/component/tips/123?#{q.to_query}" do
      yield
    end
  end
end
