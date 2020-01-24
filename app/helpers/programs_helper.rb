module ProgramsHelper

  # Options:  :link_classes,
  def linked_icon_for_program(program, options={})
    if program.url.present?
      link_to icon('far', 'external-link-alt', class: 'fa-fw'), program.url, target: '_blank', title: program.name, class: options[:link_classes]
    else
      link_to icon('far', 'file-pdf', class: 'fa-fw'), download_event_program_path(program.conference, program), target: '_blank', title: program.name, class: options[:link_classes]
    end
  end

end
