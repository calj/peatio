class Blockchain < ActiveRecord::Base
  has_many :currencies
end

# == Schema Information
# Schema version: 20180707142007
#
# Table name: blockchains
#
#  id            :string(10)       not null, primary key
#  block_pointer :integer
#  block_number  :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
