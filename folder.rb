require './filter'
require './filter_repository'
require 'logger'

class Folder
  attr_reader :name

  def initialize(filters: nil, imap: , name:)
    @imap = imap
    @name = name
    @filters = filters || FilterRepository.new.for(folder: name)
  end

  def create_filters
    @imap.examine(@name.to_s)
    @imap.uid_search('SINCE 1-Apr-2003').each do |message_id|
      next if message_uid_previously_processed?(uid: message_id)
      envelope = @imap.uid_fetch(message_id, 'ENVELOPE')[0].attr['ENVELOPE']
      Filter.new.from_envelope(envelope: envelope, repository: @filters)
    end
    logger.debug("saving filters to #{@name}")
    @filters.save_filters
  end

  def match_filters?(envelope:)
    @filters.clear_temporary
    tfr = FilterRepository.new.for(folder: 'temporary')
    Filter.new.from_envelope(envelope: envelope, repository: tfr)
    @filters.include? tfr
  end

  private

  def message_uid_previously_processed?(uid:)
    @filters[:processed_uids].include? uid
  end

  private

  def logger
    Logger.new(STDOUT).tap do |logger|
      logger.level = Logger::WARN
      logger.level = Logger::DEBUG if ENV['DEBUG']
    end
  end
end
