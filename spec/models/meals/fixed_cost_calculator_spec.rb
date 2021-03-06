# frozen_string_literal: true

require "rails_helper"

describe Meals::FixedCostCalculator do
  let(:formula) do
    create(:meal_formula, meal_calc_type: "fixed", pantry_calc_type: pantry_calc_type,
                          pantry_fee: pantry_fee, parts_attrs: %w[4 3 0])
  end
  let(:types) { formula.types }
  let(:meal) { build(:meal, formula: formula) }
  let(:calculator) { Meals::FixedCostCalculator.new(meal) }

  before do
    meal.build_cost
    allow(meal).to receive(:signup_totals).and_return(types[0] => 9, types[1] => 3, types[2] => 2)
  end

  context "with fixed pantry_calc_type" do
    let(:pantry_calc_type) { "fixed" }
    let(:pantry_fee) { 0.5 }

    describe "price_for" do
      it "should be correct" do
        expect(calculator.price_for(types[0])).to be_within(0.005).of(4.5)
        expect(calculator.price_for(types[1])).to be_within(0.005).of(3.5)
        expect(calculator.price_for(types[2])).to be_zero
      end
    end

    describe "max_ingredient_cost" do
      it "should be correct" do
        expect(calculator.max_ingredient_cost).to be_within(0.005).of(45)
      end
    end
  end

  context "with ratio pantry_calc_type" do
    let(:pantry_calc_type) { "ratio" }
    let(:pantry_fee) { 0.1 }

    describe "price_for" do
      it "should be correct" do
        expect(calculator.price_for(types[0])).to be_within(0.005).of(4.4)
        expect(calculator.price_for(types[1])).to be_within(0.005).of(3.3)
        expect(calculator.price_for(types[2])).to be_zero
      end
    end
  end
end
