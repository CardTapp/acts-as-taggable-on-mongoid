# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActsAsTaggableOnMongoid::Errors::DuplicateTagError do
  it "is a StandardError" do
    expect(ActsAsTaggableOnMongoid::Errors::DuplicateTagError.instance_methods).to be_include :backtrace
  end
end
