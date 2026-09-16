require "test_helper"

class TicketTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ticket_type = ticket_types(:one)
    sign_in users(:one)
  end

  test "should get index" do
    get ticket_types_url
    assert_response :success
  end

  test "should get new" do
    get new_ticket_type_url
    assert_response :success
  end

  test "should create ticket_type" do
    assert_difference("TicketType.count") do
      post ticket_types_url, params: { ticket_type: { sla_hours: 2, title: "Pintura" } }
    end

    assert_redirected_to ticket_types_url
  end

  test "should get edit" do
    get edit_ticket_type_url(@ticket_type)
    assert_response :success
  end

  test "should update ticket_type" do
    patch ticket_type_url(@ticket_type), params: { ticket_type: { sla_hours: 3, title: "Hidraulica atualizada" } }
    assert_redirected_to ticket_types_url
  end

  test "should destroy ticket_type" do
    removable_type = TicketType.create!(title: "Temp type", sla_hours: 1)

    assert_difference("TicketType.count", -1) do
      delete ticket_type_url(removable_type)
    end

    assert_redirected_to ticket_types_url
  end
end
