require "application_system_test_case"

class TicketTypesTest < ApplicationSystemTestCase
  setup do
    @ticket_type = ticket_types(:one)
  end

  test "visiting the index" do
    visit ticket_types_url
    assert_selector "h1", text: "Ticket types"
  end

  test "should create ticket type" do
    visit ticket_types_url
    click_on "New ticket type"

    fill_in "Sla hours", with: @ticket_type.sla_hours
    fill_in "Title", with: @ticket_type.title
    click_on "Create Ticket type"

    assert_text "Ticket type was successfully created"
    click_on "Back"
  end

  test "should update Ticket type" do
    visit ticket_type_url(@ticket_type)
    click_on "Edit this ticket type", match: :first

    fill_in "Sla hours", with: @ticket_type.sla_hours
    fill_in "Title", with: @ticket_type.title
    click_on "Update Ticket type"

    assert_text "Ticket type was successfully updated"
    click_on "Back"
  end

  test "should destroy Ticket type" do
    visit ticket_type_url(@ticket_type)
    accept_confirm { click_on "Destroy this ticket type", match: :first }

    assert_text "Ticket type was successfully destroyed"
  end
end
