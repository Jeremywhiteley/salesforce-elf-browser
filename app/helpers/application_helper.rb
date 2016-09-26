module ApplicationHelper

  # Return the login path for the OAuth service
  def omniauth_login_path(service)
    "/auth/#{service.to_s}"
  end


  # Add a flash message
  # Params
  # +type+:: +Symbol+ that represents the flash message type (e.g. warnings, errors, info, etc.)
  # +message+:: +String+ message that is displayed to the user
  def flash_message(type, message)
    flash[type] ||= []
    flash[type] << message
  end

  def get_user_data(login_record, user_map, field)
    theUser = user_map.select { |user| user.Id == login_record.UserId}
    theUserJson = theUser[0].to_json
    theUserHash = JSON.parse(theUserJson)
    theUserHash[field]
  end

end
