# Source: https://coderwall.com/p/jsutlq/capybara-s-save_and_open_page-with-css-and-js

def show_page
  save_page Rails.root.join( 'public', 'capybara.html' )
  %x(launchy http://localhost:3000/capybara.html)
end