# frozen_string_literal: true

class ListTrac::ListTracComponent < ApplicationComponent
  def before_render
    super
    return if @error.present?
    @listings = []
    begin
      @token = token unless @preview_mode.present?
      @listings = @preview_mode.present? ? demo_listings : agent_listings
      @expand_url = @listings.any? ? component_named_expanded_path(@widget.component, params[:session_id]) : nil
      @listings = @listings.sort_by { |listing| listing[:ViewCount] }.reverse
    rescue => e
      @error = e.message
      @error_with_api = e.is_a?(RestClient::Exception) || e.is_a?(SocketError)
      log_error(e)
    end
  end

  def agent_listings
    params = {
      access_token: @token,
      TrackingType: "Agent",
      TrackingValues: session[:current_user][:mls_number],
      # TrackingValues: "364512302",
      ResponseType: "summary"
    }
    response = RestClient::Request.execute(
      method: :get,
      timeout: 10,
      url: "https://b2b.listtrac.com/RESO/OData/InternetTracking?#{params.to_query}",
      verify_ssl: false
    )
    json = JSON.parse(response, symbolize_names: true)
    raise json[:description] if json[:status] != "ok"
    json[:value] || []
  end

  def token
    pass = VendorApiAccess["list_trac"]["password"]
    key_params = {
      orgID: "stellar",
      username: VendorApiAccess["list_trac"]["username"]
    }
    json_response = RestClient::Request.execute(
      method: :get,
      url: "https://b2b.listtrac.com/api/getkey?#{key_params.to_query}",
      verify_ssl: false
    )
    response = JSON.parse(json_response, symbolize_names: true)
    Digest::MD5.hexdigest(pass + response[:key])
  end

  def demo_listings
    [
      {
        Address: "123 Main St",
        ViewCount: 100,
        InquiryCount: 10
      },
      {
        Address: "456 Main St",
        ViewCount: 200,
        InquiryCount: 20
      },
      {
        Address: "789 Main St",
        ViewCount: 300,
        InquiryCount: 30
      },
      {
        Address: "101 Main St",
        ViewCount: 400,
        InquiryCount: 40
      }
    ]
  end
end
