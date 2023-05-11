# frozen_string_literal: true

class Hurdlr::HurdlrComponent < ApplicationComponent
  def before_render
    super
    return if @error.present?
    @data = {}
    @data, @error = @library_mode ? [demo_data, nil] : user_vitals
  end

  def user_vitals
    api_post("userVitals", {userId: session[:current_user][:mls_number]})
    # api_post("userVitals", {userId: VendorApiAccess["hurdlr"]["test_user_id"]})
  end

  def api_post(endpoint, payload)
    base_url = (Rails.env.production? || Rails.env.uat?) ? "https://app.hurdlr.com/rest/v1/enterprise" : "https://sandbox.hurdlr.com/rest/v1/enterprise"
    token = VendorApiAccess["hurdlr"]["token"]
    begin
      response = RestClient::Request.execute(
        method: :post,
        timeout: 10,
        url: "#{base_url}/#{endpoint}",
        payload: payload.to_json,
        headers: {Authorization: "Bearer #{token}"}
      )
      data = JSON.parse(response, symbolize_names: true)
      [data, data[:errorMessage]] # This sort of error message does not need to be logged
    rescue => e
      @error_with_api = true
      log_error(e)
      [{}, e.message || "Unknown error getting Hurdlr data"]
    end
  end

  def demo_data
    {
      currencyType: "USD",
      revenue: 43794, # Income
      expenses: 5730, # Expenses
      overallTaxAmount: 6101, # Taxes
      afterTaxIncome: 31961, # Profit after tax
      ytdTaxSavings: 1234, # “YTD Tax Savings” or “Current Tax Savings”
      projectedTaxSavings: 1234 # Estimated Annual Savings
    }
  end
end
