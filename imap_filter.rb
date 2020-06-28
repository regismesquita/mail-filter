# frozen_string_literal: true

require 'json'
require './main'

def lambda_handler(event:, context:)
  ImapFilter.new.run
  { event: JSON.generate(event), context: JSON.generate(context.inspect) }
end
