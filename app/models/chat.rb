class Chat < ActiveRecord::Base
  acts_as_searchable(:ignore_timestamp=>true,:searchable_fields => [:name, :message], :attributes => {:created_at => :created_at})
  validates_presence_of :name, :message

end
