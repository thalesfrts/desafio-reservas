require "test_helper"

class BlocksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @block = blocks(:one)
    sign_in users(:one)
  end

  test "should get index" do
    get blocks_url
    assert_response :success
  end

  test "should get new" do
    get new_block_url
    assert_response :success
  end

  test "should create block" do
    assert_difference("Block.count") do
      post blocks_url, params: { block: { apartments_per_floor: 2, floors_count: 2, identification: "Bloco C" } }
    end

    assert_redirected_to blocks_url
  end

  test "should get edit" do
    get edit_block_url(@block)
    assert_response :success
  end

  test "should update block" do
    patch block_url(@block), params: { block: { apartments_per_floor: 3, floors_count: 2, identification: "Bloco A atualizado" } }
    assert_redirected_to blocks_url
  end

  test "should destroy block" do
    removable_block = Block.create!(identification: "Bloco Temp", floors_count: 1, apartments_per_floor: 1)

    assert_difference("Block.count", -1) do
      delete block_url(removable_block)
    end

    assert_redirected_to blocks_url
  end
end
