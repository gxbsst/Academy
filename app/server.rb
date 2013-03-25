# encoding: utf-8
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-migrations/migration_runner'
require 'dm-timestamps'
require 'pony'
require 'liquid'
require 'json'
#require "sinatra/json"

require 'pry'

def send_email feedback
  email_template = <<-EOS
  at:          {{ when }}
  Name:     {{ name }}
  Email:         {{ email }}
  Tel:         {{ tel }}
  Course:       {{ course }}

  Note:

  {{  content }}

  EOS

  body = Liquid::Template.parse(email_template).render  "name"       => feedback.name,
                                                        "email"      => feedback.email,
                                                        "tel"    => feedback.tel,
                                                        "course"    => feedback.course_name,
                                                        "content"    => feedback.content,
                                                        "when"       => Time.now.strftime("%b %e, %Y %H:%M:%S %Z")

  #Pony.mail(:to => "weston.wei@sidways.com", :from => feedback.email, :subject => "A register from #{feedback.name}", :body => body)
  Pony.mail(:to => 'weston.wei@sidways.com', :via => :smtp, :smtp => {
      :host     => 'mail.sidways.com',
      :port     => '25',
      :user     => 'patrick_contact@sidways.com',
      :password => '123456',
      :auth     => :plain,           # :plain, :login, :cram_md5, no auth by default
      :domain   => "sidways.com"     # the HELO domain provided by the client to the server
  },
     :from => feedback.email,
     :subject =>  "A register from #{feedback.name}",
     :body => body
  )
end


DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/academy.db")

class Feedback
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :email, String
  property :tel, String
  property :course_name, String
  property :content, Text
  property :user_agent, String
  property :ip, String
  property :created_at, DateTime
  property :updated_at, DateTime
end

migration 1, :create_feedback_table do
  up do
    create_table :people do
      column :id,   Integer, :serial => true
      column :name, String, :size => 50
      column :email, String
      column :tel, String
      column :course_name, String
      column :content, Text
      column :ip, String
      column :user_agent, String
      column :created_at, DateTime
      column :updated_at, DateTime
    end
  end
  down do
    drop_table :people
  end
end

migrate_up!

# Create or upgrade all tables at once, like magic
configure :development do
  DataMapper.auto_upgrade!
end

before do
  headers "Content-Type" => "text/html; charset=utf-8"
end

set :public_folder, 'public'

get '/' do
  redirect '/index.html'
end

post '/create' do

  content_type :json

  f = Feedback.new
  f.ip =  @env['REMOTE_ADDR']
  f.user_agent =  @env['HTTP_USER_AGENT']
  f.name = params[:name]
  f.email = params[:email]
  f.tel = params[:tel]
  f.course_name = params[:course_name]
  f.content = params[:note]
  f.save

  begin
    send_email(f)
    @sent = true
    {success: true}.to_json
  rescue Exception => e
    @failure = "Ooops, it looks like something went wrong while attempting to send your email. Mind trying again now or later? :)"
    {success: true}.to_json
  end
  #redirect "/success.html"

end


