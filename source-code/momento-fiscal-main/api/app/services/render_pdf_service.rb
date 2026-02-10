# frozen_string_literal: true

# Class that renders a PDF file from a template
class RenderPdfService < ApplicationService
  def initialize(template:, layout: "layouts/layout", formats: [:pdf], assigns: {})
    @template = template
    @layout   = layout
    @formats  = formats
    @assigns  = assigns
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def call
    raise ArgumentError, "missing required arguments" if [@template, @layout, @formats].any?(&:blank?)

    a = PDFKit.new(
      pdf_html,
      page_size:             "A4",
      margin_top:            18,
      margin_bottom:         15,
      margin_left:           0,
      margin_right:          0,
      enable_external_links: true,
      # disable_smart_shrinking: true,
      header_html:           "file://#{header_file.path}",
      footer_html:           "file://#{footer_file.path}"
    )

    a.to_pdf
  ensure
    footer_file.close
    footer_file.unlink

    header_file.close
    header_file.unlink
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def pdf_html
    @pdf_html ||= ActionController::Base.new.render_to_string(
      template: @template,
      layout:   @layout,
      assigns:  @assigns,
      formats:  @formats
    )
  end

  def footer_file
    @footer_file ||= begin
      footer_file = Tempfile.new(["footer_", ".html"])
      footer_file << ActionController::Base.new.render_to_string(template: "layouts/_pdf_footer", formats: [:pdf])
      footer_file.rewind
      footer_file
    end
  end

  def header_file
    @header_file ||= begin
      header_file = Tempfile.new(["header_", ".html"])
      header_file << ActionController::Base.new.render_to_string(template: "layouts/_pdf_header", formats: [:pdf])
      header_file.rewind
      header_file
    end
  end
end
