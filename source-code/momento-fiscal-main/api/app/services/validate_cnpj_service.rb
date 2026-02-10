# frozen_string_literal: true

# ValidateCnpjService
class ValidateCnpjService < ApplicationService
  def initialize(cnpj:)
    @cnpj = cnpj&.gsub(/[^0-9]/, "")
  end

  def call
    return false if cnpj_blank_or_invalid_length?
    return false if cnpj_invalid_sequence?
    return false unless valid_checksum?

    true
  end

  private

  def cnpj_blank_or_invalid_length?
    @cnpj.nil? || @cnpj.length != 14
  end

  def cnpj_invalid_sequence?
    sequence = @cnpj[0] * 14
    sequence == @cnpj
  end

  # rubocop:disable Metrics/AbcSize, Layout/LineLength
  def valid_checksum?
    value = @cnpj.chars.map(&:to_i)

    sum = (value[0] * 5) + (value[1] * 4) + (value[2] * 3) + (value[3] * 2) + (value[4] * 9) + (value[5] * 8) + (value[6] * 7) + (value[7] * 6) + (value[8] * 5) + (value[9] * 4) + (value[10] * 3) + (value[11] * 2)
    sum -= (11 * (sum / 11))
    result1 = [0, 1].include?(sum) ? 0 : 11 - sum

    return false unless result1 == value[12]

    sum = (value[0] * 6) + (value[1] * 5) + (value[2] * 4) + (value[3] * 3) + (value[4] * 2) + (value[5] * 9) + (value[6] * 8) + (value[7] * 7) + (value[8] * 6) + (value[9] * 5) + (value[10] * 4) + (value[11] * 3) + (value[12] * 2)
    sum -= (11 * (sum / 11))
    result2 = [0, 1].include?(sum) ? 0 : 11 - sum

    return true if result2 == value[13]

    false
  end
  # rubocop:enable Metrics/AbcSize, Layout/LineLength
end
