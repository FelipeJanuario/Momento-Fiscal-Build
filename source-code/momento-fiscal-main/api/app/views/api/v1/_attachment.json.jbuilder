# frozen_string_literal: true

return unless attachment&.attached?

json.name attachment&.filename&.to_s
json.signed_id attachment&.signed_id
json.file_size ApplicationController.helpers.number_to_human_size(
  attachment.blob.byte_size,
  precision: 2,
  separator: "."
)
json.content_type attachment.blob.content_type
json.path Rails.application.routes.url_helpers.rails_blob_path(attachment.blob, only_path: true)

if attachment.variable?
  base64_variant = Base64.encode64(
    attachment.variant(
      resize_to_fit: [24, 24],
      format:        :png,
      saver:         {
        subsample_mode: "on",
        strip:          true,
        interlace:      true,
        sharpen:        "0x0.5",
        quality:        80
      }
    ).processed.download
  )

  json.thumbnail "data:image/png;base64,#{base64_variant}"
end
