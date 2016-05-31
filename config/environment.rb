# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Webapp::Application.initialize!

#Exception Notification
Webapp::Application.config.middleware.use ExceptionNotifier,
  :email => {
    :email_prefix => "[BFR ROBOT ERROR] ",
    :sender_address => %{"BFR Robot" <notifier@boulderfoodrescue.org>},
    :exception_recipients => %w{rylanb@gmail.com cphillips@smallwhitecube.com}
  }
