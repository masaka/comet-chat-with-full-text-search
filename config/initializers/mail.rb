# ---------- config/initializers/mail.rb ----------
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :domain => "smtp.gmail.com",
  :authentication => :login,
  :user_name => "[your_username]",
  :password => "[your_password]"
}
