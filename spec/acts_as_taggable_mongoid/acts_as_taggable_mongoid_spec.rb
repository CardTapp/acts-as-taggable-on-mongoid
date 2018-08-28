# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid do
  it "has a version number" do
    expect(ActsAsTaggableOnMongoid::VERSION).not_to be nil
  end

  it "can create a database record" do
    Tagged.create string_field: "This is a string"

    expect(Tagged.count).to eq 1
  end
end
