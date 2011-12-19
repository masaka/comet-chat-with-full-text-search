class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
  
    @body[:url]  = "http://[your_FQDN]/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://[your_FQDN]/welcome"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "[your_email_address]"
      @subject     = "[your_chat_title] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
