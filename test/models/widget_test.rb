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

  test "component should be set to external_{id} if not otherwise provided after create" do
    widget = Widget.create(name: "My Widget")
    assert_equal "external_#{widget.id}", widget.component
  end

  test "submission notes should be cleared when status is changed to review" do
    widget = Widget.create(name: "My Widget", status: "submitted", submission_notes: "Some notes")
    assert_equal "Some notes", widget.submission_notes
    widget.update(status: "review")
    assert_nil widget.submission_notes
  end

  test "submission notes should be cleared when status is changed from review" do
    widget = Widget.create(name: "My Widget", status: "review", submission_notes: "Some notes")
    assert_equal "Some notes", widget.submission_notes
    widget.update(status: "rejected")
    assert_nil widget.submission_notes
  end

  test "widget submission log should be created when status is changed" do
    widget = Widget.create(name: "My Widget", status: "unsubmitted")
    assert_equal 0, widget.widget_submission_logs.count
    widget.update(status: "submitted")
    assert_equal 1, widget.widget_submission_logs.count
  end

  test "widget submission log should be created when status is submitted on create" do
    widget = Widget.create(name: "My Widget", status: "submitted")
    assert_equal 1, widget.widget_submission_logs.count
  end

  test "widget submission log should not be created when status is changed from draft, ready, or deactivated" do
    widget = Widget.create(name: "My Widget", status: "draft")
    assert_equal 0, widget.widget_submission_logs.count
    widget.update(status: "ready")
    assert_equal 0, widget.widget_submission_logs.count
    widget.update(status: "deactivated")
    assert_equal 0, widget.widget_submission_logs.count
    widget.update(status: "draft")
    assert_equal 0, widget.widget_submission_logs.count
  end

  test "widget submission log should be revised if widget is updated while status is submitted" do
    widget = Widget.create(name: "My Widget", status: "submitted", submission_notes: "Some notes")
    assert_equal 1, widget.widget_submission_logs.count
    widget.update(submission_notes: "Updated notes")
    assert_equal 1, widget.widget_submission_logs.count
    assert_equal "Updated notes", widget.widget_submission_logs.first.notes
  end
end
