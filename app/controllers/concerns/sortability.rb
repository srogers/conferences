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
        sql = sqlize_sort_param(default)   # this is the "neutral" sort, where we revert to the default, but leave the sort param in play
      else
        sql = sqlize_sort_param(params[:sort])
      end
    else
      params[:sort] = default        # awkward direct tweaking of params - but needed to make this stick and flow up
      sql =sqlize_sort_param(default)
    end

    return Arel.sql(sql)             # So it's not necessary to call Arel.sql() on this in the controller
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
    column = expression.downcase.delete('^a-z_.,\(\)')    # nothing can be in column name except a-z, underscore, comma, and the dot between table and column - parens are to preserve lower(x) as a viable option
    @current_sortable_column = column                     # The view needs to look at this to see what we're sorting by - params[:sort] may be it, or may have kicked back to default sort
    # If the column sort contains a comma, then we have to seed in the sort direction twice, e.g. 'column1 ASC, column2 ASC'
    # There's no provision for two separate sorting directions. Currently only event city,state works like this.
    column_with_direction = column.split(',').map{|c| c + direction}.join(',')
    return sanitize_sql_for_order column_with_direction
  end
end
