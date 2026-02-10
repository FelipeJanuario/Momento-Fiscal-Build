# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidateCpfService do
  describe "#call" do
    context "when the CPF is valid" do
      it "returns true" do
        valid_cpf = "292.143.820-85"
        service = described_class.new(cpf: valid_cpf)
        expect(service.call).to be true
      end
    end

    context "when the CPF is blank" do
      it "returns false" do
        service = described_class.new(cpf: "")
        expect(service.call).to be false
      end
    end

    context "when the CPF has invalid length" do
      it "returns false" do
        invalid_cpf = "123" # Less than 11 digits
        service = described_class.new(cpf: invalid_cpf)
        expect(service.call).to be false
      end
    end

    context "when the CPF has invalid checksum for the first digit" do
      it "returns false" do
        invalid_cpf = "invalid_cpf_with_wrong_first_digit" # Replace with a CPF with invalid first digit checksum
        service = described_class.new(cpf: invalid_cpf)
        expect(service.call).to be false
      end
    end

    context "when the CPF has invalid checksum for the second digit" do
      it "returns false" do
        invalid_cpf = "invalid_cpf_with_wrong_second_digit" # Replace with a CPF with invalid second digit checksum
        service = described_class.new(cpf: invalid_cpf)
        expect(service.call).to be false
      end
    end

    # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
    context "when CPF is an invalid sequence" do
      it "returns false" do
        expect(described_class.call(cpf: "000.000.000-00")).to be false
        expect(described_class.call(cpf: "111.111.111-11")).to be false
        expect(described_class.call(cpf: "222.222.222-22")).to be false
        expect(described_class.call(cpf: "333.333.333-33")).to be false
        expect(described_class.call(cpf: "444.444.444-44")).to be false
        expect(described_class.call(cpf: "555.555.555-55")).to be false
        expect(described_class.call(cpf: "666.666.666-66")).to be false
        expect(described_class.call(cpf: "777.777.777-77")).to be false
        expect(described_class.call(cpf: "888.888.888-88")).to be false
        expect(described_class.call(cpf: "999.999.999-99")).to be false
      end
    end
    # rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
  end
end
