module Components::ExternalWidgetHelper
  def populate_url_variables(url)
    return url unless url.include?("{")
    url_variables.each do |key, value|
      url.gsub!(Regexp.new("{#{key}}", Regexp::IGNORECASE), URI.encode_www_form_component(value.to_s))
    end
    url
  end

  private

  def url_variables
    {
      mls_number: session.dig(:current_user, :mls_number),
      nrds_number: session.dig(:current_user, :nrds_number),
      full_name: session.dig(:current_user, :full_name)
    }
  end
end
