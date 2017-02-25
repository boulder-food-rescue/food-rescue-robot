Webapp::Application.config.secret_token = if Rails.env.production?
                                            ENV['SECRET_KEY_BASE']
                                          else
                                            'dev_0aac6asdfalsdfjkalsdfkdlsfljkasljkdflkajsflkjsdlkjflksdfjdsklf'
                                          end
