require 'aws-sdk-s3'
require 'logger'
require 'json'

class FilterRepository
  FILTER_CATEGORIES = [:sender, :receiver, :subject, :processed_uids]
  BUCKET = ENV['AWS_BUCKET']
  KEY = ENV['AWS_OBJECT_KEY']

  def for(folder:)
    @folder = folder
    logger.debug "Folder #{folder}"
    filters[folder] ||= {}
    trim_filters(filters[folder])
    self
  end

  def clear_temporary
    filters['temporary'] = {}
  end

  def [](key)
    filters[@folder][key]
  end

  def user_emails
    user_emails = JSON.load(ENV['USER_EMAILS'] || "[]")
    raise TypeError unless user_emails.is_a? Array
    user_emails
  end

  def trim_filters(filters_folder)
    logger.debug "Trimming #{filters_folder}"
    FILTER_CATEGORIES.each do |fc|
      logger.debug "Trimming #{fc}"
      filters_folder[fc] ||= []
      filters_folder[fc].uniq!
      filters_folder[fc].compact!
    end
    filters_folder
  end

  def s3_object
    logger.debug 'Accessing S3'
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(BUCKET)
    obj = bucket.object(KEY)
  end

  def s3_object_read
    s3_object.get.body.read.tap{|readed| logger.debug "Result read: #{readed}"}
  end

  def filters
    @@filter ||= Marshal.load(s3_object_read)
  end

  def save_filters
    s3_object.upload_stream do |write_stream|
      IO.copy_stream(
        StringIO.new(Marshal.dump(filters)),
        write_stream
      )
    end
  end
  
  def include?(other_repository)
    FILTER_CATEGORIES.each do |fc|
      other_repository[fc].each do |filter|
        if self[fc].include?(filter) 
          puts "Moving to #{@folder} , based on #{fc}: #{filter}"
          return true 
        end
      end
    end
    false
  end

  private

  def logger
    Logger.new(STDOUT).tap do |logger|
      logger.level = Logger::WARN
      logger.level = Logger::DEBUG if ENV['DEBUG']
    end
  end
end
