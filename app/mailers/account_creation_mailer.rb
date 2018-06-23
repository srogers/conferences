class AccountCreationMailer < ApplicationMailer

  def verify_email(user, creator)
    @user = user
    @account_activation_url = activation_url(user.perishable_token)
    @created_by_admin = creator.present? && creator.admin?
    mail(to: @user.email, subject: 'Confirm your new  Account')
  end

  def pending_activation_notice(pending_user)
    @pending_user = pending_user
    users = Role.where(:name => Role::ADMIN).first.users
    users.each do |user|
      @user = user
      mail(to: @user.email, subject: 'New  account needs approval')
    end
  end

  def activation_notice(user)
    @user = user
    mail(to: @user.email, subject: 'Your  account has been approved')
  end
end
