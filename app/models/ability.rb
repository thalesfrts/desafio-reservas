# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    if user.administrator?
      can :manage, :all
      return
    end

    if user.collaborator?
      can :read, TicketType
      can :read, TicketStatus
      can [ :read, :update ], Ticket, ticket_type_id: user.assigned_ticket_type_ids
      can [ :read, :create ], Comment, ticket: { ticket_type_id: user.assigned_ticket_type_ids }
      return
    end

    # Morador: só gestão de seus próprios chamados
    can :read, Unit, id: user.unit_ids
    can :read, TicketType
    can :read, Ticket, unit_id: user.unit_ids
    can :create, Ticket, user_id: user.id
    can [ :read, :create ], Comment, ticket: { unit_id: user.unit_ids }
  end
end
