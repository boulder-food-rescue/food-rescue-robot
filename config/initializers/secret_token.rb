if Rails.env.production?
  Webapp::Application.config.secret_token = ENV['SECRET_KEY_BASE']
else
  Webapp::Application.config.secret_token = 'dev_0aac6asdfalsdfjkalsdfkdlsfljkasljkdflkajsflkjsdlkjflksdfjdsklf'
end
