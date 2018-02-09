require 'workflow_setup'
require 'net/sftp'

# Submit an ETD to ProQuest.
# Called by GraduationJob.
# This job will re-try until the submission has been completed. When it has
# successfully completed ProQuest submission (i.e., when it finishes the
# upload_file method without raising an exception) it calls the ProquestCompletionJob.
# That way ProquestCompletionJob never gets called unless the submission has gone
# through, and if it is delayed for some reason ProquestCompletionJob will record
# when the upload actually happened, not just record the first time it was attempted.
class ProquestJob < ActiveJob::Base
  queue_as Hyrax.config.ingest_queue_name

  # @param [String] work_id - the id of the work object
  def perform(work_id)
    @work = Etd.find(work_id)
    return unless ProquestJob.submit_to_proquest?(@work)
    # 1. Create a directory. Done. See config/environments
    # 2. Write XML file there Done.
    # 3. Write PDF and supplementary files there. Done.
    # 4. Zip the directory. Done. Tasks 1 - 4 encapsulated in export_zipped_proquest_package
    @upload_file = @work.export_zipped_proquest_package
    # 5. Transmit the zip to ProQuest
    transmit_file
    cleanup_file
    ProquestCompletionJob.perform_later(work_id)
  end

  # Does this work meet the criteria required for ProQuest submission?
  # @param [ActiveFedora::Base] work - the work object
  # @return [Boolean]
  def self.submit_to_proquest?(work)
    # Condition 0: Has is already been submitted to ProQuest?
    return false if work.proquest_submission_date.first.instance_of?(Date)
    # Condition 1: Is it from Laney Graduate School?
    return false unless work.school.first == "Laney Graduate School"
    # Condition 2: Has it been approved?
    return false unless work.to_sipity_entity.workflow_state_name == 'approved'
    # Condition 3: Has the degree been awarded?
    return false unless work.degree_awarded.instance_of?(Date)
    # Condition 4: Is this a PhD?
    return true if work.degree.first == "PhD"
    # Condition 5: Or is this a Master's student who has chosen to submit?
    return true if work.choose_proquest_submission.first == true
    false
  end

  # Transmit the exported file to ProQuest SFTP server
  def transmit_file
    Net::SFTP.start(ENV['PROQUEST_SFTP_HOST'], ENV['PROQUEST_SFTP_USER'], password: ENV['PROQUEST_SFTP_PASSWORD']) do |sftp|
      Rails.logger.debug "Uploading #{@upload_file} to ProQuest"
      sftp.upload!(@upload_file, "#{@work.upload_file_id}.zip")
    end
  end

  # Delete the transmitted file
  def cleanup_file
    File.delete(@upload_file)
  end
end
