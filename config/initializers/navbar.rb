BootstrapNavbar.configure do |config|
  config.bootstrap_version = '3.2.0.2'
  config.current_url_method = 'request.original_url'
end

ActionView::Base.send :include, BootstrapNavbar::Helpers
