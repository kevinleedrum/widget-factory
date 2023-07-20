require "test_helper"

class Api::WidgetsControllerTest < ActionController::TestCase
  test "should get widgets" do
    get :index
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal 3, response_body.length
  end

  test "should get single widget" do
    widget = widgets(:one)
    get :show, params: {id: widget.id}
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal widget.id, response_body["id"]
    assert_equal 1, response_body["widget_submission_logs"].length
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
    put :update, params: {
      id: widget.id,
      widget: new_properties
    }
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
    post :create, params: {
      widget: new_properties
    }
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
end
