#! /usr/bin/ruby
require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'obscenity'
require "sinatra/reloader"
also_reload 'views/index.erb'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db.sqlite3")

class Gift
  include DataMapper::Resource
  property :id, Serial
  property :name, String,  :length => 1..25
  property :event, String, :length => 1..25
  property :hours, Integer, :required => true
  property :created_on, DateTime
  property :updated_at, DateTime

  validates_with_method :filter_profanity

  def filter_profanity
    if Obscenity.profane?(self.name) || Obscenity.profane?(self.event)
      [ false, "Obscenity detected, try a different name"]
    else
      return true
    end
  end

end

DataMapper.finalize
#DataMapper.auto_upgrade!

# helpers
class Numeric
  def percent_of(n)
    self.to_f / n.to_f * 100.0
  end
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

enable :sessions

get '/' do
  @gifts = Gift.all
  @total_hours = Gift.sum(:hours)
  @percentage = @total_hours.percent_of(5000)
  @errors = session[:errors]

  #how many digits?
  digits = @total_hours.to_s.length
  rounder = 10**(2)
  @start_zoom = ((@total_hours/rounder).to_i)*rounder
  @finish_zoom = @start_zoom + 100
  @zoom_percentage = @total_hours - @start_zoom
	erb :index 
end

post '/timegift/create' do
  session[:feet] = "left foot right foot"
	time_gift = Gift.create(  	:name => params[:name],
  									:event => params[:event],
                    :hours => params[:hours],
  									:created_on => Time.now,
  									:updated_at => Time.now )
  if time_gift.save
    session[:errors] = nil
    redirect '/'
  else
    session[:errors] = time_gift.errors.values.map{|e| e.to_s}
    redirect '/'
  end
end