# encoding: UTF-8
# frozen_string_literal: true

namespace :currencies do
  desc 'Adds missing currencies to database defined at config/seed/currencies.yml.'
  task seed: :environment do
    require 'yaml'
    Currency.transaction do
      YAML.load_file(Rails.root.join('config/seed/currencies.yml')).each do |hash|
        unless Currency.exists?(id: hash.fetch('id'))
          Currency.create!(hash)
        end
        if hash['type'] == 'coin'
          blockchain_id = hash['options']['api_client'] == 'ERC20' ? 'eth' : hash['id']
          blockchain = Blockchain.find_or_create_by(id: blockchain_id)
          currency = Currency.find(hash['id'])
          currency.blockchain = blockchain
          currency.save!
        end
      end
    end
  end
end
