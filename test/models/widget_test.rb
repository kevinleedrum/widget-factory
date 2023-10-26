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

  test "submission notes and admin response should be cleared when rejecting" do
    widget = Widget.create(name: "My Widget", status: "review", submission_notes: "Some notes", admin_response: "Some response")
    assert_equal "Some notes", widget.submission_notes
    assert_equal "Some response", widget.admin_response
    widget.update(status: "rejected")
    assert_nil widget.submission_notes
    assert_nil widget.admin_response
  end

  test "widget submission log should be created when widget is drafted" do
    widget = Widget.create(name: "My Widget", status: "unsubmitted")
    assert_equal 1, widget.widget_submission_logs.count
  end

  test "widget submission log should be created when status is changed" do
    widget = Widget.create(name: "My Widget", status: "unsubmitted")
    assert_equal 1, widget.widget_submission_logs.count
    widget.update(status: "submitted")
    assert_equal 2, widget.widget_submission_logs.count
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

  test "create_revision should correctly create a new widget revision" do
    widget = Widget.create(
      name: "Parent Widget",
      description: "Parent Description",
      partner: "Parent Partner",
      logo_link_url: "https://example.com/parent-logo-link",
      external_url: "https://example.com/parent-external",
      external_preview_url: "https://example.com/parent-external-preview",
      external_expanded_url: "https://example.com/parent-external-expanded",
      submitted_by_uuid: "parent-submitted-by-uuid"
    )
    logo = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "logo.png")),
      filename: "logo.png",
      content_type: "image/png"
    )
    widget.logo.attach(logo)
    revision = widget.create_revision
    assert_not_nil revision
    assert_equal widget.id, revision.parent_widget_id
    assert_equal "unsubmitted", revision.status
    assert_equal widget.name, revision.name
    assert_equal widget.description, revision.description
    assert_equal widget.partner, revision.partner
    assert_equal widget.logo_link_url, revision.logo_link_url
    assert_equal widget.external_url, revision.external_url
    assert_equal widget.external_preview_url, revision.external_preview_url
    assert_equal widget.external_expanded_url, revision.external_expanded_url
    assert_equal widget.submitted_by_uuid, revision.submitted_by_uuid
    assert revision.logo.attached?
    assert_equal widget.logo.blob, revision.logo.blob
  end

  test "merge_into_parent should update the parent with revision attributes" do
    parent = Widget.create(name: "Parent Widget", description: "Parent Description")
    revision = parent.create_revision
    revision.update(
      name: "Revised Widget",
      description: "Revised Description",
      partner: "Revised Partner",
      logo_link_url: "https://example.com/revised-logo-link",
      external_url: "https://example.com/revised-external",
      external_preview_url: "https://example.com/revised-external-preview",
      external_expanded_url: "https://example.com/revised-external-expanded"
    )
    logo = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "logo.png")),
      filename: "logo.png",
      content_type: "image/png"
    )
    revision.logo.attach(logo)
    merged_widget = revision.merge_into_parent
    assert_equal "Revised Widget", merged_widget.name
    assert_equal "Revised Description", merged_widget.description
    assert_equal "Revised Partner", merged_widget.partner
    assert_equal "https://example.com/revised-logo-link", merged_widget.logo_link_url
    assert_equal "https://example.com/revised-external", merged_widget.external_url
    assert_equal "https://example.com/revised-external-preview", merged_widget.external_preview_url
    assert_equal "https://example.com/revised-external-expanded", merged_widget.external_expanded_url
    assert merged_widget.logo.attached?
    assert_equal revision.logo.blob, merged_widget.logo.blob
  end

  test "parents scope should return widgets without parent widgets" do
    parent = Widget.create(name: "Parent Widget")
    revision = Widget.create(name: "Revised Widget", parent_widget: parent)
    assert_includes Widget.parents, parent
    assert_not_includes Widget.parents, revision
  end
end
