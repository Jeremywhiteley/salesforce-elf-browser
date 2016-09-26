class EventLogFilesController < ApplicationController
  include ActionController::Live

  ALL_EVENTS_TYPE = "All"

  before_filter :setup_databasedotcom_client

  def to_hash
    hash = {}; self.attributes.each { |k,v| hash[k] = v }
    return hash
  end

  def index
    redirect_to root_path unless logged_in?

    @username = session[:username]

    if params[:daterange].nil?
      default_params_redirect
      return
    elsif params[:daterange].nil? || params[:daterange].empty?
      flash_message(:warnings, "The 'daterange' query parameter is invalid. Displaying default date range.")
      default_params_redirect
      return
    end

    begin
      @start_date, @end_date = date_range_parser(params[:daterange])
    rescue ArgumentError => e
      flash_message(:warnings, "The 'daterange' query parameter with value '#{params[:daterange]}' is invalid. Displaying default date range.")
      default_params_redirect
      return
    end

    begin
      @start_time = params[:startTime]
      @end_time = params[:endTime]
      @log_files = @client.query("SELECT logintime, userid, Application FROM LoginHistory where logintime >= #{date_to_time(@start_date)} AND logintime <= #{date_to_time(@end_date)} AND (hour_in_day(convertTimezone(logintime)) > #{@end_time} or hour_in_day(convertTimezone(logintime)) < #{@start_time}) and userid not in ('00561000001p5NAAAY', '00561000001atvkAAA', '00561000001ZZlDAAW', '00561000001ZZlQAAW', '00561000001ZZksAAG', '005610000013vc5AAA', '005610000013K1yAAE','00561000001p5N5AAI','00561000001a1haAAA') AND Application <> 'Salesforce for Outlook' ORDER BY logintime")
      @user_map = @client.query("SELECT Alias,Email,FirstName,Id,IsActive,LastName,Username FROM User")
    rescue Databasedotcom::SalesForceError => e
      # Session has expired. Force user logout.
      if e.message == "Session expired or invalid"
        redirect_to logout_path
      else
        raise e
      end
    end
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
    redirect_to event_log_files_path(daterange: "#{default_date.to_s} to #{default_date.to_s}", startTime: "8", endTime: "21")
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
