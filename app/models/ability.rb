class Ability
  include CanCan::Ability

  def initialize(user)
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    user ||= User.new # guest user (not logged in)

    # Currently, everything  is handled by controller filters, but the framework is here....
    if user.admin?
      can :manage, :all

    elsif user.editor?
      can :read, :all
      can :manage, Conference
      can :manage, ConferenceUser
      can :destroy, Conference, :creator_id => user.id
      can [:read, :download] , Document
      can :manage, Presentation
      can :manage, PresentationSpeaker
      can :manage, Publication
      can :manage, Speaker

    elsif user.reader?
      can :read, :all

    else
      # Some read abilities are going to be required to allow social media linking
    end
  end
end
