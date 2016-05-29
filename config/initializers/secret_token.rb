if Rails.env.development?
  Webapp::Application.config.secret_key_base = 'dev_0aac6asdfalsdfjkalsdfkdlsfljkasljkdflkajsflkjsdlkjflksdfjdsklf'
else
  Webapp::Application.config.secret_token = ENV['SECRET_KEY_BASE']
end

