require "rails_helper"
require "base64"

RSpec.describe "Comments", type: :request do
  describe "POST /tickets/:ticket_id/comments" do
    it "allows resident to comment on ticket from linked unit" do
      resident = create(:user, :resident)
      unit = create(:unit)
      create(:user_unit, user: resident, unit: unit)
      ticket = create(:ticket, user: resident, unit: unit)

      sign_in resident

      expect do
        post ticket_comments_path(ticket), params: {
          comment: { body: "Comentário do morador" }
        }
      end.to change(Comment, :count).by(1)

      expect(response).to redirect_to(ticket_path(ticket))
    end

    it "does not allow resident to comment outside linked units" do
      resident = create(:user, :resident)
      foreign_ticket = create(:ticket)

      sign_in resident

      expect do
        post ticket_comments_path(foreign_ticket), params: {
          comment: { body: "Tentativa sem escopo" }
        }
      end.not_to change(Comment, :count)

      expect(response).to redirect_to(tickets_path)
    end

    it "allows collaborator to comment inside assigned ticket-type scope" do
      collaborator = create(:user, :collaborator)
      assigned_type = create(:ticket_type)
      create(:user_ticket_type, user: collaborator, ticket_type: assigned_type)
      ticket = create(:ticket, ticket_type: assigned_type)

      sign_in collaborator

      expect do
        post ticket_comments_path(ticket), params: {
          comment: { body: "Comentário do colaborador" }
        }
      end.to change(Comment, :count).by(1)

      expect(response).to redirect_to(ticket_path(ticket))
    end

    it "allows resident to attach photos when creating a comment" do
      resident = create(:user, :resident)
      unit = create(:unit)
      create(:user_unit, user: resident, unit: unit)
      ticket = create(:ticket, user: resident, unit: unit)

      sign_in resident

      image_file = Tempfile.new([ "comment-photo", ".png" ])
      image_file.binmode
      image_file.write(
        Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9oNbyzQAAAAASUVORK5CYII=")
      )
      image_file.rewind

      uploaded_file = Rack::Test::UploadedFile.new(image_file.path, "image/png")

      expect do
        post ticket_comments_path(ticket), params: {
          comment: {
            body: "Comentario com foto",
            photos: [ uploaded_file ]
          }
        }
      end.to change(Comment, :count).by(1).and change(AuditLog, :count).by(1)

      expect(Comment.last.photos).to be_attached
      expect(AuditLog.last.action).to eq("comment.created")
      expect(response).to redirect_to(ticket_path(ticket))
    ensure
      image_file.close!
    end
  end
end
