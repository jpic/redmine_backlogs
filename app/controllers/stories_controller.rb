class StoriesController < ApplicationController
  unloadable
  before_filter :find_story, :only => [:edit, :update, :show, :delete]
  before_filter :find_project  # NOTE: this is important. Otherwise, Redmine will throw a 403
  before_filter :authorize

  def index
    @include_meta = true
    @stories = Story.find(:all, 
                          :conditions => ["project_id=? AND tracker_id in (?) AND updated_on > ?", @project, Story.trackers, params[:after]],
                          :order => "updated_on ASC")
    @last_updated = Story.find(:first, 
                          :conditions => ["project_id=? AND tracker_id in (?)", @project, Story.trackers],
                          :order => "updated_on DESC")

    render :action => "index", :layout => false
  end

  def new
    render :partial => "story", :object => Story.new
  end

  def create
    attribs = params.select{|k,v| k != 'id' and Story.column_names.include? k }
    attribs = Hash[*attribs.flatten]
    attribs['author_id'] = User.current.id
    story = Story.new(attribs)
    if story.save!
      if params[:prev]==''
        story.insert_at 1
      else
        story.insert_at Story.find(params[:prev]).position + 1
      end
      status = 200
      render :partial => "story", :object => story
    else
      text = "ERROR"
      status = 500
      render :text => text, :status => status
    end
  end

  def update
    story = Story.find(params[:id])
    attribs = params.select{|k,v| k != 'id' and Story.column_names.include? k }
    attribs = Hash[*attribs.flatten]
    result = story.journalized_update_attributes! attribs
    if result

      if params[:prev]==''
        story.insert_at 1
      else
        story.insert_at Story.find(params[:prev]).position + 1
      end

      text = "Story updated successfully."
      status = 200
    else
      text = "ERROR: Story could not be saved."
      status = 500
    end
    render :text => text, :status => status
  end

  private

  def find_project
    @project = if params[:project_id].nil?
                 @story.project
               else
                 Project.find(params[:project_id])
               end
  end

  def find_story
    @story = Story.find(params[:id])
  end
end
