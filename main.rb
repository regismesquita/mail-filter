require 'net/imap'
require './folder'

class ImapFilter
  FILTER_FOLDERS = [:Papertrail, :Imbox, :screenout, :Feed]
  DESTINATION_FOLDER = 'INBOX'

  def initialize
    @filter_folders = []
    @folders = []
    generate_folders
  end

  def run
    create_filters_from_existing_folders
    inbox_filter
    close_imap_connection
  end

  def close_imap_connection
    imap_connection.disconnect
  end

  def imap_connection
    @imap ||= Net::IMAP.new(ENV['IMAP_SERVER'],ssl: true).tap do |imap|
      imap.authenticate('LOGIN', ENV['IMAP_USER'] , ENV['PASSWORD'])
    end
  end

  def generate_folders
    FILTER_FOLDERS.each do |ff|
      @folders << Folder.new(imap: imap_connection, name: ff)
    end
  end

  def create_filters_from_existing_folders
    @folders.each(&:create_filters)
  end

  def inbox_filter
    imap_connection.examine(DESTINATION_FOLDER)
    imap_connection.uid_search('SINCE 1-Apr-2003').each do |message_id|
      envelope = imap_connection.uid_fetch(message_id, 'ENVELOPE')[0].attr['ENVELOPE']
      @folders.each do |ff|
        if ff.match_filters?(envelope: envelope)
          puts "moving #{envelope.inspect} to #{ff.name}"
          imap_connection.uid_move([message_id], ff.name.to_s)
          break
        end
      end
    end
  end
end
