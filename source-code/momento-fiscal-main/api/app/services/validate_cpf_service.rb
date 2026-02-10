# frozen_string_literal: true

# ValidateCpfService
class ValidateCpfService < ApplicationService
  def initialize(cpf:)
    @cpf = cpf
  end

  def call
    return false if cpf_blank_or_invalid_length?

    cpf_digits = extract_digits
    return false unless valid_sequence?(cpf_digits)
    return false unless valid_checksum?(cpf_digits)

    true
  end

  private

  def cpf_blank_or_invalid_length?
    @cpf.nil? || @cpf.gsub(/[^0-9]/, "").length != 11
  end

  def extract_digits
    @cpf.gsub(/[^0-9]/, "")
  end

  def valid_checksum?(digits)
    first_check_digit_valid?(digits) && second_check_digit_valid?(digits)
  end

  def valid_sequence?(digits)
    sequence = digits[0] * 11
    sequence != digits
  end

  def first_check_digit_valid?(digits)
    sum = calculate_sum(digits, 10)
    remainder = calculate_remainder(sum)
    remainder == digits[9].to_i
  end

  def second_check_digit_valid?(digits)
    sum = calculate_sum(digits, 11)
    remainder = calculate_remainder(sum)
    remainder == digits[10].to_i
  end

  def calculate_sum(digits, factor)
    sum = 0
    (factor - 1).times do |i|
      sum += digits[i].to_i * (factor - i)
    end
    sum
  end

  def calculate_remainder(sum)
    remainder = (sum * 10) % 11
    remainder == 10 ? 0 : remainder
  end
end
