# manages things controllers use to do sorting
module Sortability

  include ActiveRecord::Sanitization::ClassMethods

  # Pass in an expression before getting the current sort.
  # Use the param form '-start_date', not the SQL form 'start_date DESC'
  # Must use the same expression defined in sort_params() for column sort indicators to work.
  def default_sort(expression)
    params[:sort] = expression if params[:sort].blank?
  end

  # Builds the current sort SQL based on a param string like: [+,-]expression
  # The sort param can only be a single expression or column. Can't do multi-sort. That doesn't fit with the column select UI.
  def params_to_sql(default=nil)
    if params[:sort].present?
      sqlize_sort_param(params[:sort])
    else
      params[:sort] = default     # awkward direct tweaking of params - but needed to make this stick and flow up
      sqlize_sort_param(default)
    end
  end

  private

  # pass in a sort indicator in params form like '-start_date' and get back a SQL ORDER argument like 'start_date DESC'.
  # The expression can be any legit SQL, but only about a single column - not column_1,column_2
  def sqlize_sort_param(expression)
    direction = case expression.first
    when '+' then ' ASC'
    when '-' then ' DESC'
    else
      ' DESC'
    end
    column = ['+','-'].include?(expression[0]) ? expression.from(1) : expression
    return sanitize_sql_for_order column + direction
  end
end
