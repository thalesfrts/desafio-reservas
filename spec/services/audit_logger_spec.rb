require "rails_helper"

RSpec.describe AuditLogger do
  describe ".log" do
    it "prefers the forwarded client IP when present" do
      request = instance_double(
        ActionDispatch::Request,
        get_header: "198.51.100.10, 10.0.0.2",
        remote_ip: "10.0.0.2",
        request_id: "request-id",
        user_agent: "RSpec",
        request_method: "POST",
        fullpath: "/tickets",
        path_parameters: { controller: "tickets", action: "create" }
      )

      log = described_class.log(
        actor: create(:user, :administrator),
        action: "ticket.created",
        request: request
      )

      expect(log.ip_address).to eq("198.51.100.10")
    end
  end
end
