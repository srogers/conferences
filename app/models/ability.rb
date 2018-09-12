class Ability
  include CanCan::Ability

  def initialize(user)
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    if user.present?

      if user.admin?
        can :manage, :all

      elsif user.editor?
        can :read, :all
        can :manage, Conference
        can [:chart], Conference
        can :manage, ConferenceUser
        can :destroy, Conference, :creator_id => user.id
        can [:read, :download] , Document
        can :manage, Presentation
        can [:chart, :tags], Presentation
        can :manage, PresentationSpeaker
        can :manage, Publication
        can :manage, Speaker
        can [:chart], Speaker

      elsif user.reader?
        can :read, :all
        can [:chart], Conference
        can [:chart, :tags], Presentation
        can [:edit, :update], Speaker, :id => user.speaker_id
        can [:chart], Speaker

      else
        logger.error "user #{user.id} with undefined role"
      end

    else
      # Some read abilities are going to be required to allow social media linking
      can :read, Conference
      can [:chart], Conference
      can :read, Presentation
      can [:chart, :tags], Presentation
      can :read, Speaker
      can [:chart], Speaker
    end
  end
end
