require 'test_helper'

class SchedulesControllerTest < ActionController::TestCase
  setup do
    @schedule = schedules(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:schedules)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create schedule" do
    assert_difference('Schedule.count') do
      post :create, :schedule => { :admin_notes => @schedule.admin_notes, :day_of_week => @schedule.day_of_week, :donor_id => @schedule.donor_id, :needs_training => @schedule.needs_training, :prior_volunteer_id => @schedule.prior_volunteer_id, :public_notes => @schedule.public_notes, :recipient_id => @schedule.recipient_id, :time_start => @schedule.time_start, :time_stop => @schedule.time_stop }
    end

    assert_redirected_to schedule_path(assigns(:schedule))
  end

  test "should show schedule" do
    get :show, :id => @schedule
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @schedule
    assert_response :success
  end

  test "should update schedule" do
    put :update, :id => @schedule, :schedule => { :admin_notes => @schedule.admin_notes, :day_of_week => @schedule.day_of_week, :donor_id => @schedule.donor_id, :needs_training => @schedule.needs_training, :prior_volunteer_id => @schedule.prior_volunteer_id, :public_notes => @schedule.public_notes, :recipient_id => @schedule.recipient_id, :time_start => @schedule.time_start, :time_stop => @schedule.time_stop }
    assert_redirected_to schedule_path(assigns(:schedule))
  end

  test "should destroy schedule" do
    assert_difference('Schedule.count', -1) do
      delete :destroy, :id => @schedule
    end

    assert_redirected_to schedules_path
  end
end
