# frozen_string_literal: true

json.page (params[:page] || 1).to_i
json.per_page (params[:per_page] || 10).to_i
json.total paginated_collection.offset(nil).limit(nil).size
