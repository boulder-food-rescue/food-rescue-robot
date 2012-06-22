require 'test_helper'

class LogsControllerTest < ActionController::TestCase
  setup do
    @log = logs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:logs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create log" do
    assert_difference('Log.count') do
      post :create, :log => { :description => @log.description, :flag_for_admin => @log.flag_for_admin, :notes => @log.notes, :num_reminders => @log.num_reminders, :orig_volunteer_id => @log.orig_volunteer_id, :transport => @log.transport, :weighed_by => @log.weighed_by, :weight => @log.weight, :when => @log.when }
    end

    assert_redirected_to log_path(assigns(:log))
  end

  test "should show log" do
    get :show, :id => @log
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @log
    assert_response :success
  end

  test "should update log" do
    put :update, :id => @log, :log => { :description => @log.description, :flag_for_admin => @log.flag_for_admin, :notes => @log.notes, :num_reminders => @log.num_reminders, :orig_volunteer_id => @log.orig_volunteer_id, :transport => @log.transport, :weighed_by => @log.weighed_by, :weight => @log.weight, :when => @log.when }
    assert_redirected_to log_path(assigns(:log))
  end

  test "should destroy log" do
    assert_difference('Log.count', -1) do
      delete :destroy, :id => @log
    end

    assert_redirected_to logs_path
  end
end
