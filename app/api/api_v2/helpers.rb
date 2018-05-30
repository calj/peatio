# encoding: UTF-8
# frozen_string_literal: true

module APIv2
  module Helpers
    def authenticate!
      current_user or raise AuthorizationError
    end

    def deposits_must_be_permitted!
      if current_user.level < ENV['MINIMUM_MEMBER_LEVEL_FOR_DEPOSIT'].to_i
        raise Grape::Exceptions::Base.new(text: 'Please pass the corresponding verification step to deposit funds.', status: 401)
      end
    end

    def withdraws_must_be_permitted!
      if current_user.level < ENV['MINIMUM_MEMBER_LEVEL_FOR_WITHDRAW'].to_i
        raise Grape::Exceptions::Base.new(text: 'Please pass the corresponding verification step to withdraw funds.', status: 401)
      end
    end

    def trading_must_be_permitted!
      if current_user.level < ENV['MINIMUM_MEMBER_LEVEL_FOR_TRADING'].to_i
        raise Grape::Exceptions::Base.new(text: 'Please pass the corresponding verification step to enable trading.', status: 401)
      end
    end

    def redis
      @r ||= KlineDB.redis
    end

    def current_user
      # JWT authentication provides member email.
      if env.key?('api_v2.authentic_member_email')
        Member.find_by_email(env['api_v2.authentic_member_email'])
      end
    end

    def current_market
      @current_market ||= Market.find params[:market]
    end

    def time_to
      params[:timestamp].present? ? Time.at(params[:timestamp]) : nil
    end

    def build_order(attrs)
      (attrs[:side] == 'sell' ? OrderAsk : OrderBid).new \
        state:         ::Order::WAIT,
        member:        current_user,
        ask:           Currency.enabled.find_by!(code: current_market.base_unit).id,
        bid:           Currency.enabled.find_by!(code: current_market.quote_unit).id,
        market:        current_market,
        ord_type:      attrs[:ord_type] || 'limit',
        price:         attrs[:price],
        volume:        attrs[:volume],
        origin_volume: attrs[:volume]
    end

    def create_order(attrs)
      order = build_order(attrs)
      Ordering.new(order).submit
      order
    rescue => e
      report_exception_to_screen(e)
      raise CreateOrderError, e.inspect
    end

    def create_orders(multi_attrs)
      orders = multi_attrs.map(&method(:build_order))
      Ordering.new(orders).submit
      orders
    rescue => e
      report_exception_to_screen(e)
      raise CreateOrderError, e.inspect
    end

    def order_param
      params[:order_by].downcase == 'asc' ? 'id asc' : 'id desc'
    end

    def format_ticker(ticker)
      { at: ticker[:at],
        ticker: {
          buy: ticker[:buy],
          sell: ticker[:sell],
          low: ticker[:low],
          high: ticker[:high],
          last: ticker[:last],
          vol: ticker[:volume]
        }
      }
    end

    def get_k_json
      key = "peatio:#{params[:market]}:k:#{params[:period]}"

      if params[:timestamp]
        ts = JSON.parse(redis.lindex(key, 0)).first
        offset = (params[:timestamp] - ts) / 60 / params[:period]
        offset = 0 if offset < 0

        JSON.parse('[%s]' % redis.lrange(key, offset, offset + params[:limit] - 1).join(','))
      else
        length = redis.llen(key)
        offset = [length - params[:limit], 0].max
        JSON.parse('[%s]' % redis.lrange(key, offset, -1).join(','))
      end
    end
  end
end
