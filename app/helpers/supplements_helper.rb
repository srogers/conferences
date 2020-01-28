module SupplementsHelper

  # Options:  :link_classes,
  def linked_icon_for_supplement(supplement, options={})
    if supplement.url.present?
      link_to icon('far', 'external-link-alt', class: 'fa-fw'), supplement.url, target: '_blank', title: supplement.name, class: options[:link_classes]
    else
      link_to icon('far', 'file-pdf', class: 'fa-fw'), download_event_supplement_path(supplement.conference, supplement), target: '_blank', title: supplement.name, class: options[:link_classes]
    end
  end

end
