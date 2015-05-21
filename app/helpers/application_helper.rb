# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def add_action(text, url)
    @actions ||= []
    @actions.push([text,url])
  end

  def display_online(item)
    item.online? ? "<span class='online'>Online</span>" : "<span class='offline'>Offline</span>"
  end

  def display_disk_free(free, used, size)
    @tera = 1024 * 1024 * 1024 * 1024;
    "%.2fT (%.0f%% of %.2fT)" % [ free.to_f / @tera, 100.0 * (free.to_f / size.to_f), size.to_f / @tera ]
  end

  def build_action_list
    @actions ||= []
    if @actions.size > 0
      content_for :sidebar do
        raw('<ul>' +
        @actions.map do | action |
          "<li>" + link_to( action[0], h(action[1])) + "</li>"
        end.join("\n") + '</ul>')
      end
    end
  end

  def selected_tab?(cont)
    @controller.controller_name == cont ? 'active' : 'inactive'
  end

  def display_backup_duration(job)
    return 'Unknown' unless job
    return 'Not yet started' if job.status == 'queued'
    start_time = job.started || job.created_at
    end_time = job.updated_at

    if job.status == 'running'
      start_time = job.started || job.created_at
      end_time = Time.new
    end

    distance_of_time_in_words(start_time, end_time )
  end

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end

  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"))
  end

end
