require "test_helper"

class TicketStatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ticket_status = ticket_statuses(:one)
    sign_in users(:one)
  end

  test "should get index" do
    get ticket_statuses_url
    assert_response :success
  end

  test "should get new" do
    get new_ticket_status_url
    assert_response :success
  end

  test "should create ticket_status" do
    assert_difference("TicketStatus.count") do
      post ticket_statuses_url, params: { ticket_status: { is_default: false, is_final: false, name: "Aguardando vistoria" } }
    end

    assert_redirected_to ticket_statuses_url
  end

  test "should get edit" do
    get edit_ticket_status_url(@ticket_status)
    assert_response :success
  end

  test "should update ticket_status" do
    editable_status = ticket_statuses(:two)

    patch ticket_status_url(editable_status), params: { ticket_status: { is_default: false, is_final: false, name: "Em análise" } }
    assert_redirected_to ticket_statuses_url
  end

  test "should destroy ticket_status" do
    removable_status = TicketStatus.create!(name: "Temp status", is_default: false, is_final: false)

    assert_difference("TicketStatus.count", -1) do
      delete ticket_status_url(removable_status)
    end

    assert_redirected_to ticket_statuses_url
  end
end
