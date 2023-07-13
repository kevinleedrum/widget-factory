# Configures datadog for APM tracing
# See: https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md
service_name = "widget-factory"
if !Rails.env.test?
  Datadog.configure do |c|
    dd_enabled = ENV["DD_APM_ENABLED"].to_s == "true"
    c.tracing.enabled = dd_enabled
    if dd_enabled
      c.env = Rails.env
      c.service = service_name
      c.version = ENV["BUILD_VERSION"] || ENV["GIT_TAG"] || `git describe --tags`.chomp
      c.agent.host = ENV["DD_AGENT_SERVICE_HOST"] || ENV["DD_AGENT_HOST"] || "localhost"
      c.agent.port = ENV["DD_AGENT_SERVICE_PORT"] || ENV["DD_TRACE_AGENT_PORT"] || "8126"
      c.tracing.instrument :rack, {request_queuing: true, service_name: "#{service_name}-rack"}
      c.tracing.instrument :rails, {service_name: "#{service_name}-rails"}
      c.tracing.instrument :redis, {service_name: "#{service_name}-redis"}
      c.tracing.instrument :active_record, {service_name: "#{service_name}-postgres"}
      c.tracing.instrument :dalli, {service_name: "#{service_name}-memcached"}
      c.tracing.instrument :pg, {service_name: "#{service_name}-pg"}
      c.tracing.instrument :http, {service_name: "#{service_name}-http"}
      c.tracing.instrument :resque, {service_name: "#{service_name}-resque"}
      c.tracing.instrument :rest_client, {service_name: "#{service_name}-rest"}
    end
  end
end
