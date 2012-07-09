require 'test_helper'

class FoodTypesControllerTest < ActionController::TestCase
  setup do
    @food_type = food_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:food_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create food_type" do
    assert_difference('FoodType.count') do
      post :create, :food_type => { :name => @food_type.name }
    end

    assert_redirected_to food_type_path(assigns(:food_type))
  end

  test "should show food_type" do
    get :show, :id => @food_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @food_type
    assert_response :success
  end

  test "should update food_type" do
    put :update, :id => @food_type, :food_type => { :name => @food_type.name }
    assert_redirected_to food_type_path(assigns(:food_type))
  end

  test "should destroy food_type" do
    assert_difference('FoodType.count', -1) do
      delete :destroy, :id => @food_type
    end

    assert_redirected_to food_types_path
  end
end
