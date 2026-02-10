# frozen_string_literal: true

json.array! @consulting_proposals, partial: "api/v1/consulting_proposals/consulting_proposal", as: :consulting_proposal
