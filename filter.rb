class Filter
  def from_envelope(envelope:, repository:)
    @envelope = envelope
    @from_email = from_email
    @repository = repository
    @to_email = envelope.to[0].mailbox + '@' + envelope.to[0].host
    @subject = envelope.subject

    # The filter is generated with the following order
    # 1- By the receiver ( received by the user but not addresed to the user.)
    # 2- By the subject ( Containing something between brackets on the subject.)
    # 3- By the sender ( If no other condition is met we generate based on the sender email )

    filter_by_receiver || filter_by_subject || filter_by_sender
  end

  private

  def from_email
    name = @envelope.from[0].name
    # If email comes from 33mail extract email for filtering from sender name
    from_33_mail = begin
                     name.match('33Mail')
                   rescue StandardError
                     false
                   end

    return name.match(/'.*'/).to_s.tr("\'", '') if from_33_mail
    @envelope.from[0].mailbox + '@' + @envelope.from[0].host
  end

  def filter_by_receiver
    # If the email is not addressed to the user, it is a good filter.
    return false if @repository.user_emails.include? @to_email
    
    @repository[:receiver] << @to_email
  end

  def filter_by_subject
    #if the subject contains words between brackets , it is most
    #likely an mailing list identificator so we use it.
    #
    # We also match Any text before bracket as we 
    # may have messages like "Re: [foobar]"
    matching_filter = @subject.match('\A.*?\[.*?\]').to_s || ''
    return false if matching_filter == ''
    @repository[:subject] << matching_filter
  end

  def filter_by_sender
    @repository[:sender] << @from_email
  end
end
