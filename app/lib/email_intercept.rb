require 'yaml'

class EmailIntercept
  def self.delivering_email(message)
    do_not_send_file = Rails.root.join('config', 'emory', 'do_not_send.yml')
    unless File.file? do_not_send_file
      Rails.logger.error "Missing config file: #{do_not_send_file}"
      return
    end
    do_not_send = YAML.load_file(do_not_send_file)
    message.to.each do |recipient|
      message.perform_deliveries = false if do_not_send.include? recipient
    end
  end
end
