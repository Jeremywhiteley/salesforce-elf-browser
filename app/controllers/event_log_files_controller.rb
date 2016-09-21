class EventLogFilesController < ApplicationController
  include ActionController::Live

  ALL_EVENTS_TYPE = "All"

  before_filter :setup_databasedotcom_client

  def index
    redirect_to root_path unless logged_in?

    @username = session[:username]
    if not session.has_key?("event_types")
      session[:event_types] = get_event_types
    end
    @event_types = session["event_types"]
  end

  def show
  end

  private
  # return [start_date, end_date] from a query string (e.g. "2015-01-01 to 2015-01-02"). Returned dates are of Date class.
  def date_range_parser(query_string)
    begin
      start_date, end_date = query_string.split("to").map { |date_str| date_str.strip! }. map { |date_str| Date.parse(date_str) }
    rescue
      raise ArgumentError, "unable to parse date"
    end
    raise ArgumentError, "end date must be on or after begin date" if end_date < start_date
    [start_date, end_date]
  end

  # Returns the default date for filter.
  def default_date
    # We set yesterday as default date since that's the latest log file that is generated.
    Date.today - 1
  end

  def default_params_redirect
    redirect_to event_log_files_path(daterange: "#{default_date.to_s} to #{default_date.to_s}", eventtype: ALL_EVENTS_TYPE, startTime: "8", endTime: "21")
  end

  # Helper method to transform date (e.g. 2015-01-01) to time in ISO8601 format (e.g. 2015-01-01T00:00:00.000Z)
  def date_to_time(date)
    date.to_time(:utc).to_formatted_s(:iso8601)
  end

  # helper method to dynamically generate the valid event log file event types
  def get_event_types
    pick_list_values = []
    fields = @client.describe_sobject("EventLogFile")["fields"]
    for field in fields
      if field["name"] == "EventType"
         field["picklistValues"].each {|v| pick_list_values.push(v["value"])}
        break
      end
    end
    return pick_list_values.dup.unshift(ALL_EVENTS_TYPE)
  end

end
