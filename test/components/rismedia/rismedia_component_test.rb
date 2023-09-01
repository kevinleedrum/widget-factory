# frozen_string_literal: true

require "test_helper"

class Rismedia::RismediaComponentTest < ViewComponent::TestCase
  def setup
    @widget = Widget.create(
      name: "Latest from RISMedia",
      component: "rismedia",
      partner: "RISMedia",
      logo_link_url: "https://moxiworks.com"
    )
    @widget.logo.attach(io: File.open(Rails.root.join("test", "fixtures", "files", "logo.png")), filename: "logo.png", content_type: "image/png")
    @categories = ["news", "events", "reports"]
    @error = nil
  end

  # Inline component tests

  def test_inline_component_renders_tabs
    with_inline_component do
      with_articles do
        tab_list = rendered.css("[role='tablist']").to_html
        tabs = tab_list.scan(/<button>/).count
        tab_panels = tab_list.scan(/<section>/).count
        assert_equal(3, tabs)
        assert_equal(3, tab_panels)
      end
    end
  end

  def test_inline_component_renders_articles
    with_inline_component do
      with_articles do
        assert_equal(6, rendered.to_html.scan(/<article>/).count)
        @categories.each do |category|
          @articles[category].take(2).each do |article|
            ["title", "url", "author", "thumbnailLink"].each do |key|
              assert_includes(rendered.to_html, article[key])
            end
          end
        end
      end
    end
  end

  # Expanded component tests

  def test_expanded_component_renders_tabs
    with_expanded_component do
      with_articles do
        tab_list = rendered.css("[role='tablist']").to_html
        tabs = tab_list.scan(/<button>/).count
        tab_panels = tab_list.scan(/<section>/).count
        assert_equal(3, tabs)
        assert_equal(3, tab_panels)
      end
    end
  end

  def test_expanded_component_renders_articles
    with_expanded_component do
      with_articles do
        assert_equal(9, rendered.to_html.scan(/<article>/).count)
        @categories.each do |category|
          @articles[category].each do |article|
            ["title", "url", "author", "thumbnailLink"].each do |key|
              assert_includes(rendered.to_html, article[key])
            end
          end
        end
      end
    end
  end

  private

  def rendered
    render_inline(Rismedia::RismediaComponent.new(preview_mode: "noninteractive"))
  end

  def with_inline_component
    with_request_url "/component/rismedia/12345" do
      yield
    end
  end

  def with_expanded_component
    with_request_url "/component/rismedia/expanded/12345" do
      yield
    end
  end

  def with_articles
    instance_variable_set(:@articles, {
      "news" => stub_articles("news"),
      "events" => stub_articles("events"),
      "reports" => stub_articles("reports")
    }) do
      yield
    end
  end

  def stub_articles(category)
    [
      {
        title: "#{category.capitalize} Article 1",
        url: "https://example.com/#{category}-article1",
        author: "John Doe",
        thumbnailLink: "https://example.com/#{category}-article1.jpg"
      },
      {
        title: "#{category.capitalize} Article 2",
        url: "https://example.com/#{category}-article2",
        author: "John Doe",
        thumbnailLink: "https://example.com/#{category}-article2.jpg"
      },
      {
        title: "#{category.capitalize} Article 3",
        url: "https://example.com/#{category}-article3",
        author: "John Doe",
        thumbnailLink: "https://example.com/#{category}-article3.jpg"
      }
    ]
  end
end
