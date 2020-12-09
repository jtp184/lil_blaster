# Add a patch to pull fixtures in as well
module FactoryBot
  class << self
    def fixtures
      @fixtures ||= Dir.entries('./spec/fixtures')
                       .reject { |f| f =~ /^\./ }
                       .map { |f| [f, File.read("./spec/fixtures/#{f}")] }
                       .to_h
                       .transform_keys(&:to_sym)
    end
  end
end

FactoryBot.define do
  factory :manchester_protocol do
    gap { 80_000 }
    pulse_values { { header: [4511, 4540], one: [520, 1730], zero: [520, 600] } }
    system_data { 0xE0E0 }
    post_bit { 520 }

    factory :alternate_manchester do
      pulse_values { { header: [4200, 4240], one: [560, 1720], zero: [560, 680] } }
      post_bit { 560 }
    end
  end

  factory :codex do
    remote_name { 'Samsung' }
    protocol factory: manchester_protocol
    codes { { power: 16_575, volume_up: 57_375, volume_down: 53_295 } }
  end
end
