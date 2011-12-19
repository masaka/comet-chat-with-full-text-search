require 'rubygems'
require 'active_record'
require 'active_record/fixtures'

ActiveRecord::Schema.define(:version => 1) do
  create_table "stories" do |t|
    t.string   "title"
    t.text     "body"
    t.integer  "popularity", :default =>0
    t.timestamps
  end
end

class Story < ActiveRecord::Base
  acts_as_searchable :searchable_fields=>[:title, :body]
end

require File.expand_path("../lib/estraier_admin", File.dirname(__FILE__))
admin = EstraierAdmin.new(ActiveRecord::Base.configurations["test"][:estraier])
admin.create_node(Story.search_backend.node_name)

