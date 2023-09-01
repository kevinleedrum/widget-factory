# frozen_string_literal: true

require "test_helper"

class WidgetPanel::WidgetPanelComponentTest < ViewComponent::TestCase
  def setup
    @widget = Widget.create(
      name: "My Widgets",
      component: "widget_panel",
      partner: ""
    )
  end

  # Inline (My Widgets) component tests

  def test_inline_component_renders_panel
    with_inline_component([]) do
      assert_includes(
        rendered.css(".widget_panel").to_html,
        "My Widgets"
      )
    end
  end

  # Widget component is rendered in the panel if:
  # - a UserWidget record exists for the widget,
  # - and the widget component is in the list of permitted components (query param)
  def test_panel_renders_component
    instance_variable_set(:@user_widgets, [user_widgets(:one)]) do
      with_inline_component(["widget_one"]) do
        assert_includes(
          rendered.css("ol").to_html,
          "Widget One"
        )
        assert_includes(
          rendered.css(".empty-state").to_html,
          "hidden"
        )
      end
    end
  end

  # Widget component is NOT rendered in the panel if:
  # - a UserWidget record exists for the widget,
  # - BUT the widget component is NOT in the list of permitted components (query param)
  def test_panel_does_not_render_unpermitted_component
    instance_variable_set(:@user_widgets, [user_widgets(:one)]) do
      with_inline_component do
        refute_includes(
          rendered.to_html,
          "Widget One"
        )
        refute_includes(
          rendered.css(".empty-state").to_html,
          "hidden"
        )
      end
    end
  end

  # Widget component is NOT rendered in the panel if:
  # - a UserWidget record does NOT exist for the widget
  # - even when the widget component is in the list of permitted components (query param)
  def test_panel_only_renders_user_widgets
    instance_variable_set(:@user_widgets, []) do
      with_inline_component(["widget_one"]) do
        refute_includes(
          rendered.to_html,
          "Widget One"
        )
        refute_includes(
          rendered.css(".empty-state").to_html,
          "hidden"
        )
      end
    end
  end

  # Expanded (Widget Library) component tests

  def test_expanded_component_renders_modal
    with_expanded_component do
      assert_includes(
        rendered.css("mx-modal").to_html,
        "Library"
      )
    end
  end

  # Widget component is rendered in the modal if:
  # - the widget component is in the list of permitted components (query param)
  # - AND the widget is activated (it's in @active_widgets)
  def test_modal_renders_active_permitted_widget
    instance_variable_set(:@active_widgets, [widgets(:one)]) do
      with_expanded_component(["widget_one"]) do
        assert_includes(
          rendered.css("[data-widget-id=\"1\"]").to_html,
          "Widget One"
        )
      end
    end
  end

  # "Add" button is hidden if the widget is already in @user_widgets
  def test_modal_hides_add_button_for_added_widget
    instance_variable_set(:@active_widgets, [widgets(:one)]) do
      instance_variable_set(:@user_widgets, [user_widgets(:one)]) do
        with_expanded_component(["widget_one"]) do
          assert_includes(
            rendered.css("[data-widget-id=\"1\"] .add-button").to_html,
            "hidden"
          )
        end
      end
    end
  end

  # Widget component is NOT rendered in the modal if:
  # - the widget component is in the list of permitted components (query param)
  # - BUT the widget is NOT in @active_widgets
  def test_modal_does_not_render_inactive_widget
    instance_variable_set(:@active_widgets, []) do
      with_expanded_component(["widget_one"]) do
        refute_includes(
          rendered.to_html,
          "Widget One"
        )
      end
    end
  end

  # Widget component is NOT rendered in the modal if:
  # - the widget component is NOT in the list of permitted components (query param)
  # - even when the widget is activated (it's in @active_widgets)
  def test_modal_does_not_render_unpermitted_widget
    instance_variable_set(:@active_widgets, [widgets(:one)]) do
      with_expanded_component do
        refute_includes(
          rendered.to_html,
          "Widget One"
        )
      end
    end
  end

  private

  def rendered
    render_inline(WidgetPanel::WidgetPanelComponent.new(preview_mode: "noninteractive"))
  end

  def with_inline_component(components = [])
    with_request_url "/component/widget_panel/12345?components=#{components.join(",")}" do
      yield
    end
  end

  def with_expanded_component(components = [])
    with_request_url "/component/widget_panel/expanded/12345?components=#{components.join(",")}" do
      yield
    end
  end
end
