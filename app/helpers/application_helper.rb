# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # Returns the path on which the application is mounted (e.g., '/myapp' or simply '/')
  def application_root
    path = request.env['REQUEST_PATH']
    if path
      path.ends_with?('/') ? path[0..-2] : path[0..-1]
    else
      ''
    end
  end
end
