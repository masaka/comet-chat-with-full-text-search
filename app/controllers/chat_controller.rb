require 'uri'
require 'iconv'
class ChatController < ApplicationController
  before_filter :login_required

  layout 'chat', :only => :index
  skip_before_filter :verify_authenticity_token

  def index
    session[:name] ||= 'guest'

    if params[:commit]
      session[:chat] = nil
    else
      session[:chat] ||= Hash.new
    end

    session[:chat] ||= Hash.new
    #session[:chat][:search] = params[:search] if params[:search]
    session[:chat][:tag] = params[:tag] if params[:tag]
    session[:chat][:search] = params[:tag] if params[:tag]


    #検索条件作成
    if session[:chat][:search].blank?
      @chats = Chat.find(:all, :limit => 100, :order => "created_at DESC")
    else
      #SQL発行
      @chats = Chat.fulltext_search(session[:chat][:search],
               :limit => 1000,
               :order => '@id NUMA', 
               :attributes => ["created_at NUMGT " << (Time.now - 260*60*60).strftime("%Y-%m-%d %H:%M:%S")])

      @chats = @chats.reverse
    end
  end

  def show
    @chat = Chat.find(params[:id])
  end

  def listen
    session[:name] = params[:name]
    render :update do |page|
      page << <<-"EOH"
        meteorStrike['chat'].update(#{session[:name].to_json});
      EOH
    end
  end

  def talk
    if session[:chat][:tag].blank?
      tag = " "
    else
      tag = session[:chat][:tag]
    end
    @chat = Chat.new(
      :name => current_user.name, :message => ('<br /> ' <<params[:message]) <<' ' <<session[:chat][:tag] )
    if @chat.save
      content = render_component_as_string :action => 'show', :id => @chat.id
      javascript = render_to_string :update do |page|
        page.insert_html :top, 'chat-list', content
      end
      Meteor.shoot 'chat', javascript, [session[:chat][:tag]]
      render :update do |page|
        page[:message].clear
        page[:message].focus
      end
    else
      render :nothing => true
    end
  end

  def event
    message = case params[:event]
    when 'init'; "（接続方法：#{params[:type]}）"
    when 'enter'; "#{Iconv.iconv("LATIN1", "UTF-8", params[:uid]).shift} が入室しました"
    when 'leave'; "#{Iconv.iconv("LATIN1", "UTF-8", params[:uid]).shift} が退室しました"
    end
    @chat = Chat.new(
      :name => 'システム情報',
      :created_at => Time.now,
      :message => message)
    render :nothing => true
  end
  private

  def authenticate
    authenticate_or_request_with_http_basic do |user_name, password|
      user_name == USER && password == PASSWORD
    end
  end
end
