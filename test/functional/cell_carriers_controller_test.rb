require 'test_helper'

class CellCarriersControllerTest < ActionController::TestCase
  setup do
    @cell_carrier = cell_carriers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:cell_carriers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create cell_carrier" do
    assert_difference('CellCarrier.count') do
      post :create, :cell_carrier => { :format => @cell_carrier.format, :name => @cell_carrier.name }
    end

    assert_redirected_to cell_carrier_path(assigns(:cell_carrier))
  end

  test "should show cell_carrier" do
    get :show, :id => @cell_carrier
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @cell_carrier
    assert_response :success
  end

  test "should update cell_carrier" do
    put :update, :id => @cell_carrier, :cell_carrier => { :format => @cell_carrier.format, :name => @cell_carrier.name }
    assert_redirected_to cell_carrier_path(assigns(:cell_carrier))
  end

  test "should destroy cell_carrier" do
    assert_difference('CellCarrier.count', -1) do
      delete :destroy, :id => @cell_carrier
    end

    assert_redirected_to cell_carriers_path
  end
end
