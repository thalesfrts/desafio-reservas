class CommentsController < ApplicationController
    before_action :authenticate_user!

    load_and_authorize_resource :ticket
    load_and_authorize_resource :comment, through: :ticket, param_method: :comments_params

    def create
        @comment.user = current_user

        if @comment.save
                        audit_action(
                            action: "comment.created",
                            auditable: @comment,
                            context_data: {
                                ticket_id: @ticket.id,
                                photos_count: @comment.photos.count
                            },
                            change_set: audit_change_set_for(@comment)
                        )

            ::TicketNotificationService.new(ticket: @ticket, actor: current_user).notify_comment_created
            redirect_to @ticket, notice: "Comentário adicionado com sucesso."
        else
            redirect_to @ticket, alert: @comment.errors.full_messages.to_sentence
        end
    end

    private

    def comments_params
        params.require(:comment).permit(:body, photos: [])
    end
end
