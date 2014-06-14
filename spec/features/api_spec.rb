require 'spec_helper'
require 'pp'

describe 'api' do

  def get_auth_params(u)
    data = {email: u.email,password: u.password}
    post '/volunteers/sign_in.json', data
    expect(last_response.status).to eq(201)
    json = JSON.parse(last_response.body)
    {"volunteer_token" => json["authentication_token"], "volunteer_email" => u.email }
  end

  it 'can sign in' do
    v = create(:volunteer_with_assignment)
    auth_params = get_auth_params(v)
    auth_params["volunteer_token"].should_not be_nil
  end

  it 'can sign out' do
    v = create(:volunteer_with_assignment)
    auth_params = get_auth_params(v)
    auth_params["volunteer_token"].should_not be_nil

    delete "/volunteers/sign_out.json", auth_params
    last_response.status.should eq(204)

    auth_params2 = get_auth_params(v)
    auth_params2["volunteer_token"].should_not be_nil
    auth_params2["volunteer_token"].should_not eq(auth_params["volunteer_token"])
  end

  it "can get a list of logs" do
    create(:log)
    v = create(:volunteer_with_assignment)
    auth_params = get_auth_params(v)
    get "/logs.json", auth_params
    expect(last_response.status).to eq(200)
    json = JSON.parse(last_response.body)
    json.should be_an(Array)
    json.length.should eq(1)
  end

  it "will reject an unauthenticated request" do
    create(:log)
    create(:volunteer_with_assignment)
    get "/logs.json"
    expect(last_response.status).to eq(401)
  end

  it "can update an existing log"

end