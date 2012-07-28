require 'test_helper'

class TransportTypesControllerTest < ActionController::TestCase
  setup do
    @transport_type = transport_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:transport_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create transport_type" do
    assert_difference('TransportType.count') do
      post :create, :transport_type => { :name => @transport_type.name }
    end

    assert_redirected_to transport_type_path(assigns(:transport_type))
  end

  test "should show transport_type" do
    get :show, :id => @transport_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @transport_type
    assert_response :success
  end

  test "should update transport_type" do
    put :update, :id => @transport_type, :transport_type => { :name => @transport_type.name }
    assert_redirected_to transport_type_path(assigns(:transport_type))
  end

  test "should destroy transport_type" do
    assert_difference('TransportType.count', -1) do
      delete :destroy, :id => @transport_type
    end

    assert_redirected_to transport_types_path
  end
end
