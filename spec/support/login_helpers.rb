module LoginHelpers
  def login(volunteer)
    visit '/volunteers/sign_in'

    fill_in :volunteer_email,    with: volunteer.email
    fill_in :volunteer_password, with: 'SomePassword'

    click_on 'Sign in'
  end
end
