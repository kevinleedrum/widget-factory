class ComponentController < ApplicationController
  def name
    # Looks for namespaced component first.
    c = params[:name].start_with?("external") ? "external_widget" : params[:name]
    obj = begin
      Object.const_get("#{c.camelize}::#{c.camelize}Component").new
    rescue
      Object.const_get("#{c.camelize}Component").new
    end

    render(obj)
  end
end
