require 'net/http'
require 'active_merchant/billing/integrations/alipay/sign'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Alipay
        class Notification < ActiveMerchant::Billing::Integrations::Notification
          include Sign
          NOTIFY_QUERY_URL = 'http://notify.alipay.com/trade/notify_query.do'

          def complete?
            if status != "TRADE_FINISHED"
              return false
            end

            unless verify_sign
              @message = "Alipay Error: ILLEGAL_SIGN"
              return false
            end

            true
          end

          def order
            @params["out_trade_no"]
          end

          def amount
            @params["total_fee"]
          end

          def message
            @message
          end

          def item_id
            params['']
          end

          def trade_no
            params['trade_no']
          end

          # When was this payment received by the client.
          def received_at
            params['']
          end

          def payer_email
            params['']
          end

          def receiver_email
            params['seller_email']
          end

          def security_key
            params['']
          end

          # the money amount we received in X.2 decimal.
          def gross
            params['']
          end

          # Was this a test transaction?
          def test?
            params[''] == 'test'
          end

          def status
            params['trade_status']
          end

          def notify_id
            params['notify_id']
          end

          def acknowledge

            uri = URI.parse(NOTIFY_QUERY_URL)
            request_path = "#{uri.path}?partner=#{ActiveMerchant::Billing::Integrations::Alipay::ACCOUNT}&notify_id=#{self.notify_id}"

            request = Net::HTTP::Post.new(request_path)

            http = Net::HTTP.new(uri.host, uri.port)

            # http.verify_mode    = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
            #     http.use_ssl        = true

            request = http.request(request)

            raise StandardError.new("Faulty alipay result: #{request.body}") unless ["invalid","true", "false"].include?(request.body)

            request.body == "true"
          end

          private

          # Take the posted data and move the relevant data into a hash
          def parse(post)
            @raw = post
            for line in post.split('&')
              key, value = *line.scan( %r{^(\w+)\=(.*)$} ).flatten
              params[key] = value
            end
          end
        end
      end
    end
  end
end
