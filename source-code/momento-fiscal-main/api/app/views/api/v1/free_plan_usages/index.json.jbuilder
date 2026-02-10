# frozen_string_literal: true

json.array! @free_plan_usages, partial: "api/v1/free_plan_usages/free_plan_usage", as: :free_plan_usage
