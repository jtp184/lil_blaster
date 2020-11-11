require 'tempfile'

RSpec.describe LilBlaster::Codex do
  before :all do
    @codex_yaml = <<~DOC
      ---
      :metadata:
        :remote_name: Samsung
        :protocol: :Manchester
        :protocol_options:
          :gap: 10000
          :header:
          - 4511
          - 4540
          :one_value:
          - 520
          - 1730
          :zero_value:
          - 520
          - 600
          :system_data: 57568
          :post_bit: true
      :codes:
        :power: 16575
        :volume_up: 57375
        :volume_down: 53295
    DOC

    @codex = LilBlaster::Codex.from_yaml(@codex_yaml)
  end

  it 'can initialize an empty codex' do
    codex = LilBlaster::Codex.new

    expect(codex).not_to be_nil
  end

  it 'can load a codex from a yaml string' do
    codex = LilBlaster::Codex.from_yaml(@codex_yaml)

    expect(codex.remote_name).to eq('Samsung')
  end

  it 'can load from a filepath' do
    file = Tempfile.open { |f| f << @codex_yaml }
    codex = LilBlaster::Codex.load(file.path)

    expect(codex.protocol).to eq(@codex.protocol)
  end

  it 'can determine whether a symbol is known to it' do
    expect(@codex.key?(:power)).to be(true)
    expect(@codex.key?(:nonexistent)).to be(false)
  end

  it 'can generate a transmission for each symbol it knows' do
    @codex.keys.each do |ky|
      expect(@codex.call(ky)).to be_a(LilBlaster::Transmission)
    end
  end
end
