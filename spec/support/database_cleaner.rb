# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner[:mongoid].strategy = :truncation
    DatabaseCleaner.strategy           = :truncation
    DatabaseCleaner.orm                = "mongoid"

    DatabaseCleaner.clean
  end

  config.around(:each) do |example|
    DatabaseCleaner.clean

    example.run
  end
end
