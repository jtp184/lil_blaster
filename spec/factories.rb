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
  factory :manchester_protocol, class: LilBlaster::Protocol::Manchester do
    gap { 80_000 }
    pulse_values { { header: [4511, 4540], one: [517, 1732], zero: [517, 609] } }
    system_data { 0xE0E0 }
    post_bit { 517 }

    factory :alternate_manchester do
      pulse_values { { header: [4511, 4509], one: [560, 1720], zero: [560, 590] } }
      post_bit { 560 }
    end

    initialize_with { new(**attributes) }
  end

  factory :codex, class: LilBlaster::Codex do
    remote_name { 'Samsung' }
    protocol factory: :manchester_protocol
    codes { { power: 16_575, volume_up: 57_375, volume_down: 53_295 } }
    initialize_with { new(**attributes) }
  end

  factory :transmission, class: LilBlaster::Transmission do
    data do
      [
        4511, 4540, 517, 1732,
        517, 1732, 517, 1732,
        517, 609, 517, 609,
        517, 609, 517, 609,
        517, 609, 517, 1732,
        517, 1732, 517, 1732,
        517, 609, 517, 609,
        517, 609, 517, 609,
        517, 609, 517, 609,
        517, 1732, 517, 609,
        517, 609, 517, 609,
        517, 609, 517, 609,
        517, 609, 517, 1732,
        517, 609, 517, 1732,
        517, 1732, 517, 1732,
        517, 1732, 517, 1732,
        517, 1732, 517, 47_312
      ]
    end

    initialize_with { new(data: data) }
  end
end
