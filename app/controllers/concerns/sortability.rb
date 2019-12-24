# manages things controllers use to do sorting
module Sortability

  include ActiveRecord::Sanitization::ClassMethods

  # Pass in an expression before getting the current sort.
  # Use the param form '-start_date', not the SQL form 'start_date DESC'
  # Must use the same expression defined in sort_params() for column sort indicators to work.
  def default_sort(expression)
    params[:sort] = expression if params[:sort].blank?
  end

  # Builds the current sort SQL based on a param string like: [<,>]expression.
  # default DESC and ASC are indicated here by [<, >] and in header clicks by [-, +] because we need to distinguish default
  # sort from advancing the sort with a header click in order for cycling to work in the transition from DESC to nothing
  # when DESC is the default.
  # The sort param can only be a single expression or column. Can't do multi-sort. That doesn't fit with the column select UI.
  def params_to_sql(default=nil)
    if params[:sort].present?
      if params[:sort].first == '#'  # this is the case where a default DESC sort overrides the default to cycle to no sort
        params[:sort] = ''
        return nil
      elsif ! '+-'.include?(params[:sort][0])
        sqlize_sort_param(default)   # this is the "neutral" sort, where we revert to the default, but leave the sort param in play
      else
        sqlize_sort_param(params[:sort])
      end
    else
      params[:sort] = default        # awkward direct tweaking of params - but needed to make this stick and flow up
      sqlize_sort_param(default)
    end
  end

  private

  # pass in a sort indicator in params form like '-start_date' and get back a SQL ORDER argument like 'start_date DESC'.
  # The expression can be any legit SQL, but only about a single column - not column_1,column_2
  def sqlize_sort_param(expression)
    direction = case expression.first
    when '+', '>' then ' ASC'
    when '-', '<' then ' DESC'
    else
      ' DESC'
    end
    column = ['+','-','<',">"].include?(expression[0]) ? expression.from(1) : expression
    return sanitize_sql_for_order column + direction
  end
end
