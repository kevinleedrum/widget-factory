require "test_helper"

# Stub a component class
class MyWidget
  class MyWidgetComponent < ViewComponent::Base
  end
end

class WidgetTest < ActiveSupport::TestCase
  test "should be valid with a name" do
    widget = Widget.create(name: "My Widget")
    assert widget.valid?
  end

  test "activated_widgets should return activated widgets" do
    activated_fixture_count = Widget.activated_widgets.count
    Widget.create(name: "Draft Widget", status: "draft")
    Widget.create(name: "Ready Widget 1", status: "ready", activation_date: Time.now - 1.hour)
    Widget.create(name: "Ready Widget 2", status: "ready", activation_date: Time.now + 1.hour)
    Widget.create(name: "Deactivated Widget", status: "deactivated")
    activated_widgets = Widget.activated_widgets
    assert_equal 1, activated_widgets.count - activated_fixture_count
    assert_includes activated_widgets.map(&:name), "Ready Widget 1"
  end

  test "activated should return true for activated widgets" do
    # activation date in the past
    widget1 = Widget.create(name: "Activated Widget 1", status: "ready", activation_date: Time.now - 1.hour)
    # activation date in the future
    widget2 = Widget.create(name: "Activated Widget 2", status: "ready", activation_date: Time.now + 1.hour)
    # no activation date
    widget3 = Widget.create(name: "Activated Widget 3", status: "ready")
    # not ready
    widget4 = Widget.create(name: "Draft Widget", status: "draft")
    # deactivated
    widget5 = Widget.create(name: "Deactivated Widget", status: "deactivated")
    assert widget1.activated
    assert_not widget2.activated
    assert widget3.activated
    assert_not widget4.activated
    assert_not widget5.activated
  end

  test "view_component should return the correct component" do
    widget = Widget.create(name: "My Widget", component: "my_widget")
    assert_equal MyWidget::MyWidgetComponent, widget.view_component
  end

  test "view_component should return nil for unknown components" do
    widget = Widget.create(name: "My Widget", component: "unknown_component")
    assert_nil widget.view_component
  end

  test "logo_url should return nil when logo is not attached" do
    widget = Widget.new(name: "Test Widget")
    assert_nil widget.logo_url
  end

  test "logo_url should return the URL of the attached logo" do
    widget = Widget.new(name: "Test Widget")
    widget.logo.attach(io: File.open(Rails.root.join("test", "fixtures", "files", "logo.png")), filename: "logo.png", content_type: "image/png")
    assert_equal "/rails/active_storage/blobs/redirect/#{widget.logo.blob.signed_id}/#{widget.logo.blob.filename}", widget.logo_url
  end

  test "submitted_at should be set when status is submitted on create" do
    widget = Widget.create(name: "My Widget", status: "submitted")
    assert_not_nil widget.submitted_at
  end

  test "submitted_at should be set when status is changed to submitted" do
    widget = Widget.create(name: "My Widget", status: "unsubmitted")
    assert_nil widget.submitted_at
    widget.update(status: "submitted")
    assert_not_nil widget.submitted_at
  end

  test "component should be set to external_{id} after create when external_url is present" do
    widget = Widget.create(name: "My Widget", external_url: "https://www.example.com")
    assert_equal "external_#{widget.id}", widget.component
  end
end
