module PresentationsHelper

  def available_formats(presentation)
    formats = []
    formats += ['Tape'] if @presentation.tape?
    formats += ['CD'] if @presentation.cd?
    formats += ['VHS'] if @presentation.vhs?
    formats += ['e-Store'] if @presentation.estore_url.present?
    formats += ['online video'] if @presentation.video_url.present?

    formats += ['none'] if formats.empty?

    return formats.join(", ")
  end
end
