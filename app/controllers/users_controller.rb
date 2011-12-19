class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  # include AuthenticatedSystem

  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
      redirect_back_or_default('/session/new')
      flash[:notice] = "仮アカウントを作成しメールを送信しました。メール中のURLをクリックしてアカウント作成を完了させてください。"
    else
      render :action => 'new'
    end
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/welcome')
  end
  
  def show

  end

  def status
    @user = User.find(params[:id])
    render :text => @user.status
  end
  
  def statuses
    current_user.update_attributes :last_active => Time.now
    render :partial => 'statuses'
  end

  def edit
    @edit_on = true
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    success = @user.update_attributes params[:user]
    respond_to do |format|
      format.html {
        if success
          flash[:notice] = 'プロファイル情報の更新に成功しました'
          redirect_to user_url
        else
          @edit_on = true
          render :action => 'show'
        end
      }
      format.js { render :text => @user.status.blank? ? "(none)" : @user.status }
    end
  end

end
