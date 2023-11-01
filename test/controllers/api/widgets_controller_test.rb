require "test_helper"

class Api::WidgetsControllerTest < ActionDispatch::IntegrationTest
  include JwtHelper

  def setup
    @jwt = get_jwt
  end

  test "should get widgets" do
    get api_widgets_path, headers: {Authorization: @jwt}
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal 3, response_body.length
  end

  test "should get single widget" do
    widget = widgets(:one)
    get api_widget_path(widget[:id]), headers: {Authorization: @jwt}
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal widget.id, response_body["id"]
    assert_equal 1, response_body["widget_submission_logs"].length
    assert_equal response_body["revisions"].first["id"], widgets(:four).id
  end

  test "should include parent_widget in single widget" do
    widget = widgets(:four)
    get api_widget_path(widget[:id]), headers: {Authorization: @jwt}
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal widget.id, response_body["id"]
    assert_equal widget.parent_widget_id, response_body["parent_widget_id"]
    assert_equal response_body["parent_widget"]["id"], widgets(:one).id
  end

  test "should update widget" do
    widget = widgets(:one)
    new_properties = {
      name: "New Widget Name",
      description: "New Widget Description",
      status: "ready",
      activation_date: "2023-04-07T00:00:00.000Z",
      updated_by: "John Doe",
      logo_base64: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
    }
    put api_widget_path(widget[:id]), params: {widget: new_properties}, headers: {Authorization: @jwt}
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal new_properties[:name], response_body["name"]
    assert_equal new_properties[:description], response_body["description"]
    assert_equal new_properties[:status], response_body["status"]
    assert_equal new_properties[:activation_date], response_body["activation_date"]
    assert_equal new_properties[:updated_by], response_body["updated_by"]
    assert_not_nil response_body["logo_url"]
  end

  test "should create external widget" do
    new_properties = {
      name: "New Widget Name",
      description: "New Widget Description",
      status: "unsubmitted",
      external_url: "https://www.example.com",
      external_preview_url: "https://www.example.com",
      external_expanded_url: "https://www.example.com",
      submitted_by_uuid: "12345678-1234-1234-1234-123456789012",
      partner: "Example Partner",
      updated_by: "John Doe",
      logo_link_url: "https://www.example.com",
      logo_base64: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
    }
    post api_widgets_path, params: {
      widget: new_properties
    }, headers: {Authorization: @jwt}
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal new_properties[:name], response_body["name"]
    assert_equal new_properties[:description], response_body["description"]
    assert_equal new_properties[:status], response_body["status"]
    assert_equal new_properties[:external_url], response_body["external_url"]
    assert_equal new_properties[:external_preview_url], response_body["external_preview_url"]
    assert_equal new_properties[:external_expanded_url], response_body["external_expanded_url"]
    assert_equal new_properties[:submitted_by_uuid], response_body["submitted_by_uuid"]
    assert_equal new_properties[:partner], response_body["partner"]
    assert_equal new_properties[:updated_by], response_body["updated_by"]
    assert_equal new_properties[:logo_link_url], response_body["logo_link_url"]
    assert_equal "external_#{response_body["id"]}", response_body["component"]
    assert_not_nil response_body["logo_url"]
  end

  test "should create revision for widget" do
    widget = widgets(:one)
    patch api_revise_widget_path(widget[:id]), headers: {Authorization: @jwt}
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal widget.id, response_body["parent_widget_id"]
  end

  test "should retrieve existing revision instead of creating a revision" do
    widget = widgets(:one)
    patch api_revise_widget_path(widget[:id]), headers: {Authorization: @jwt}
    assert_response :success
    response_body = JSON.parse(response.body)
    assert response_body["id"], widgets(:four).id
  end

  test "should merge widget into its parent" do
    widget = widgets(:four)
    patch api_merge_widget_path(widget[:id]), headers: {Authorization: @jwt}
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal widget.parent_widget_id, response_body["id"]
    assert_equal widget.name, response_body["name"]
    assert_equal widget.description, response_body["description"]
    assert_equal widget.logo_link_url, response_body["logo_link_url"]
    assert_equal widget.external_url, response_body["external_url"]
    assert_equal widget.external_preview_url, response_body["external_preview_url"]
    assert_equal widget.external_expanded_url, response_body["external_expanded_url"]
  end

  test "should delete widget with deletable status" do
    widget = widgets(:three)
    delete api_widget_path(widget[:id]), headers: {Authorization: @jwt}
    assert_response :no_content
  end

  test "should not delete widget with non-deletable status" do
    widget = widgets(:one)
    delete api_widget_path(widget[:id]), headers: {Authorization: @jwt}
    assert_response :unprocessable_entity
  end
end
