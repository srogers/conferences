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
        can [:download] , Document
        can :manage, Presentation
        can [:chart, :tags, :heard, :notify], Presentation
        can :manage, PresentationSpeaker
        can :manage, Supplement
        can :manage, Publication
        can :manage, Speaker
        can [:chart], Speaker

      elsif user.reader?
        can :read, :all
        can [:chart, :upcoming], Conference
        can [:download] , Document
        can [:chart, :tags, :heard, :notify], Presentation
        can [:read, :latest, :chart], Publication
        can [:edit, :update], Speaker, :id => user.speaker_id
        can [:chart], Speaker

      else
        logger.error "user #{user.id} with undefined role"
      end

    else
      # Some read abilities are going to be required to allow social media linking
      can :read, Conference
      can [:chart, :upcoming], Conference
      can :download, Document
      can :read, Presentation
      can [:chart, :tags], Presentation
      can :read, Supplement
      can [:read, :latest, :chart], Publication
      can :read, Speaker
      can [:chart], Speaker
    end
  end
end
