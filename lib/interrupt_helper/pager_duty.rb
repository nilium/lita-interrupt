require 'faraday'
require 'faraday_middleware'
require 'pager_duty/connection'

module InterruptHelper
  module PagerDuty
    def pagerduty(token)
      token = token.to_s
      return nil if token.empty?
      @pagerduty_clients ||= Hash.new { |h, k|
        h[k] = ::PagerDuty::Connection.new(k)
      }
      @pagerduty_clients[token]
    end

    # @return [::Faraday]
    def events_v2
      @events_v2_client ||= Faraday.new do |conn|
        conn.url_prefix = "https://events.pagerduty.com/v2/"
        conn.use(RaiseNon202)
        conn.request(:json)
        conn.response(:json)
        conn.headers[:accept] = "application/json"
        conn.adapter(Faraday.default_adapter)
      end
    end

    class APIError < RuntimeError; end

    class RaiseNon202 < Faraday::Middleware
      def call(env)
        response = @app.call env
        raise APIError, "bad response code: #{response.status}" unless response.status == 202
        response
      end
    end
  end
end
