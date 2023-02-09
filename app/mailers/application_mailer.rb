class ApplicationMailer < ActionMailer::Base
  default from: ENV['EMAIL_DEFAULT_ADDRESS']
  layout 'mailer'
end
