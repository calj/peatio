# encoding: UTF-8
# frozen_string_literal: true

require File.join(ENV.fetch('RAILS_ROOT'), 'config', 'environment')

running = true
Signal.trap(:TERM) { running = false }

while running
  loop_processed = 0
  Currency.coins.where(enabled: true).order(id: :asc).each do |currency|
    break unless running
    Rails.logger.info { "Processing #{currency.code.upcase} deposits." }
    client    = currency.api
    processed = 0
    options   = client.is_a?(CoinAPI::ETH) ? { transactions_limit: 100 } : { }
    client.each_deposit options do |deposit|
      break unless running
      received_at = deposit[:received_at]
      Rails.logger.debug { "Processing deposit received at #{received_at.to_s('%Y-%m-%d %H:%M %Z')}." } if received_at
      Services::BlockchainTransactionHandler.new(currency).call(deposit)
      processed += 1
      Rails.logger.info { "Processed #{processed} #{currency.code.upcase} #{'deposit'.pluralize(processed)}." }
    end
    Rails.logger.info { "Finished processing #{currency.code.upcase} deposits." }
    loop_processed += processed
  rescue => e
    report_exception(e)
  end
  Kernel.sleep(5) if loop_processed == 0
end
