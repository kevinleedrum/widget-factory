module Components::ExternalWidgetHelper
  def populate_url_variables(url, demo = false)
    return url unless url.include?("{")
    variables = if demo
      demo_values
    else
      Rails.env.test? ? test_values : session_values
    end
    variables.each do |key, value|
      url.gsub!(Regexp.new("{#{key}}", Regexp::IGNORECASE), URI.encode_www_form_component(value.to_s))
    end
    url
  end

  private

  def session_values
    {
      mls_number: session.dig(:current_user, :mls_number),
      nrds_number: session.dig(:current_user, :nrds_number),
      full_name: session.dig(:current_user, :full_name)
    }
  end

  def demo_values
    {
      mls_number: "123456",
      nrds_number: "123456789",
      full_name: "Jane Doe"
    }
  end

  def test_values
    {
      mls_number: "111111",
      nrds_number: "111111111",
      full_name: "Test User"
    }
  end
end
