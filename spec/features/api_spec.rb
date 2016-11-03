require 'rails_helper'
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

  # GET /logs.json
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

  # GET /logs/:id.json
  it "can look up a log" do
    v = create(:volunteer_with_assignment)
    r = v.assignments.first.region
    l = create(:log,region:r)
    auth_params = get_auth_params(v)
    get "/logs/#{l.id}.json", auth_params
    expect(last_response.status).to eq(200)
    json = JSON.parse(last_response.body)
    json.should be_an(Hash)
    json["log"]["id"].should eq(l.id)
  end

  # GET /logs/:id/take.json
  it "can cover a shift" do
    v = create(:volunteer_with_assignment)
    r = v.assignments.first.region
    l = create(:log,region:r)
    auth_params = get_auth_params(v)
    get "/logs/#{l.id}/take.json", auth_params
    expect(last_response.status).to eq(200)
    l2 = Log.find(l.id)
    expect(l2.volunteers.include?(v)).to eq(true)
  end

  # GET /schedule_chains/:id/take.json
  it "can take a open shift" do
    v = create(:volunteer_with_assignment)
    r = v.assignments.first.region
    s = create(:schedule_chain,region:r)
    auth_params = get_auth_params(v)
    get "/schedule_chains/#{s.id}/take.json", auth_params
    expect(last_response.status).to eq(200)
    s2 = ScheduleChain.find(s.id)
    expect(s2.volunteers.include?(v)).to eq(true)
  end

  # PUT /logs/:id.json
  it "can update a log" do
    v = create(:volunteer_with_assignment)
    r = v.assignments.first.region
    l = create(:log,region:r)
    l.volunteers << v
    l.save

    auth_params = get_a uth_params(v)
    get "/logs/#{l.id}.json", auth_params
    expect(last_response.status).to eq(200)
    json = JSON.parse(last_response.body)
    pp json
    json["log_parts"].each{ |i,lp|
      json["log_parts"][i][:weight] = 42.0
      json["log_parts"][i][:count] = 5
    }
    put "/logs/#{l.id}.json", auth_params.merge(json)
    pp last_response.body
    expect(last_response.status).to eq(200)
    check = Log.find(l.id)
    check.complete.should be_true
    check.log_parts.first.weight.should eq(42.0)
    check.log_parts.first.count.should eq(5)
  end

  # GET /locations/:id.json
  it "can look up a donor or recipient" do
    v = create(:volunteer_with_assignment)
    r = v.assignments.first.region
    d = create(:donor,region:r)
    auth_params = get_auth_params(v)
    get "/locations/#{d.id}.json", auth_params
    puts last_response.body
    expect(last_response.status).to eq(200)
    json = JSON.parse(last_response.body)
    json.should be_an(Hash)
  end

  it "will reject an unauthenticated request" do
    create(:log)
    create(:volunteer_with_assignment)
    get "/logs.json"
    expect(last_response.status).to eq(401)
  end

end
