module StatusesHelper
  def format_status_day(time)
    time.to_date == Date.today ? l(:label_today).titleize : format_date(time)
  end

  # Formats the <tt>status</tt> message.  Will convert any hashtag
  # ('#tag') into a link to the hashtag page.
  #
  #   options[:highlight] => wraps the string with a highlighted
  #                          background.  Turned off when hashtags are present
  def format_status_message(status, options = {})
    response = status.message

    if status.has_hashtag?
      response = link_hash_tags(response)
    else
      response = highlight_tokens(response, [options[:highlight]])  if options[:highlight]
    end
    response
  end

  # Returns a link to the specific project for the status
  def format_project(status)
    return '' if @project # on project, no linking needed
    returning '' do |values|
      if status.project
        values << link_to(h(status.project.name), {:controller => 'statuses', :action => 'index', :id => status.project.identifier}, :class => 'smaller_project')
      end
    end
  end

  def link_hash_tags(message)
    formatted_message = []
    message.split(/ /).each do |word|
      if word.match(/#/)
        formatted_message << link_to(word, :controller => 'statuses', :action => 'tagged', :id => @project, :tag => remove_non_tag_characters(word))
      else
        formatted_message << word
      end
    end

    return formatted_message.join(' ')
  end

  # Remove all non-alphanumeric charactors except for - or _
  def remove_non_tag_characters(word)
    word.gsub(/[^[:alnum:]\-_]/,'')
  end

  def tag_cloud(tags, classes)
    max, min = 0, 0
    tags.each do |name, count|
      max = count.to_i if count.to_i > max
      min = count.to_i if count.to_i < min
    end

    divisor = ((max - min) / classes.size) + 1

    tags.each { |name, count|
      yield name, classes[(count.to_i - min) / divisor]
    }
  end


  def status_menu(&block)
    content = ''
    content << link_to(l(:redmine_status_all_status_plural), {:controller => 'statuses', :action => 'index', :id => @project}, :class => 'icon icon-index')
    content << link_to(l(:redmine_status_tag_cloud), {:controller => 'statuses', :action => 'tag_cloud', :id => @project}, :class => 'icon icon-comment')
    content << link_to(l(:redmine_status_search_statuses), {:controller => 'statuses', :action => 'search', :id => @project}, :class => 'icon icon-search')
    content << link_to(l(:redmine_status_notification_preference), {:controller => 'status_notifications', :action => 'edit'}, :class => 'icon icon-news')

    block_content = yield if block_given?
    content << block_content if block_content
    
    content_tag(:div,
                content,
                :class => "contextual")

  end

  def projects_with_create_status_permission
    User.current.projects.find(:all, :conditions => Project.allowed_to_condition(User.current, :create_statuses))
  end
end
