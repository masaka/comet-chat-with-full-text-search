class ForgotPasswordsController < ApplicationController

  def new
    @forgot_password = ForgotPassword.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @forgot_password }
    end
  end

  def create
    @forgot_password = ForgotPassword.new(params[:forgot_password])
    @forgot_password.user = User.find_by_email(@forgot_password.email)
    
    respond_to do |format|
      if @forgot_password.save
        ForgotPasswordMailer.deliver_forgot_password(@forgot_password)
        flash[:notice] = "A link to change your password has been sent to #{@forgot_password.email}."
        format.html { redirect_to '/' }
        format.xml  { render :xml => @forgot_password, :status => :created, :location => @forgot_password }
      else
        # use a friendlier message than standard error on missing email address
        if @forgot_password.errors.on(:user)
          @forgot_password.errors.clear
          flash[:error] = "We can't find a #{user_model_name} with that email. Please check the email address and try again..."
        end
        format.html { render :action => "new" }
        format.xml  { render :xml => @forgot_password.errors, :status => :unprocessable_entity }
      end
    end
  end

  def reset
    begin
      @user = ForgotPassword.find(:first, :conditions => ['reset_code = ? and expiration_date > ?', params[:reset_code], Time.now]).user
    rescue
      flash[:notice] = 'The change password URL you visited is either invalid or expired.'
      redirect_to(new_forgot_password_path)
    end    
  end

  def update_after_forgetting
    @forgot_password = ForgotPassword.find_by_reset_code(params[:reset_code])
    @user = @forgot_password.user unless @forgot_password.nil?
    
    respond_to do |format|
      if @user.update_attributes(params[:user])
       @forgot_password.destroy
        #PasswordMailer.deliver_reset_password(@user)
        ForgotPasswordMailer.deliver_reset_password(@user)
        flash[:notice] = "Password was successfully updated. Please log in."
        format.html { redirect_to '/welcome'}
      else
        flash[:notice] = 'There was a problem resetting your password. Please try again.'
        format.html { render :action => :reset, :reset_code => params[:reset_code] }
      end
    end
  end
  
end
