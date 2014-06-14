require 'spec_helper'

describe 'api' do

  def get_auth_params(u)
    data = {email: u.email,password: u.password}
    headers = {format: :json, 'CONTENT_TYPE' => 'application/json', 'HTTPS' => 'off' }
    post '/volunteers/sign_in.json', data.to_json, headers
    expect(last_response.status).to eq(201)
    json = JSON.parse(last_response.body)
    return {"auth_token" => json["auth_token"], "auth_id" => u.email }
  end

  def json_headers
    {format: :json, 'CONTENT_TYPE' => 'application/json' }
  end

  it 'can sign in' do
    v = create(:volunteer_with_assignment)
    auth_params = get_auth_params(v)
    auth_params["auth_token"].should_not be_nil
  end

  it 'can sign out' do
    v = create(:volunteer_with_assignment)
    auth_params = get_auth_params(v)
    auth_params["auth_token"].should_not be_nil

    delete "/volunteers/sign_out.json", auth_params.to_json, json_headers
    last_response.status.should eq(204)

    auth_params2 = get_auth_params(v)
    auth_params2["auth_token"].should_not be_nil
    auth_params2["auth_token"].should_not eq(auth_params["auth_token"])
  end

  it "can get a list of logs" do
    5.times do
      create(:log)
    end
    v = create(:volunteer_with_assignment)
    auth_params = get_auth_params(v)
    get "/logs.json", auth_params, json_headers
    expect(last_response.status).to eq(200)
    json = JSON.parse(last_response.body)
    json.should be_an(Array)
    json.length.should eq(5)
  end

  it "can update an existing log"

end