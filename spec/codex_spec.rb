RSpec.describe LilBlaster::Codex do
  before :all do
    @codex_yaml = <<~DOC
      ---
      :metadata:
        :remote_name: Samsung
        :protocol: :Manchester
        :protocol_options:
          :gap: 10000
          :pulse_values:
            :header:
              - 4511
              - 4540
            :one:
              - 520
              - 1730
            :zero:
              - 520
              - 600
          :system_data: 57568
          :post_bit: 520
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

  it 'can save to its filepath' do
    fpath = "/tmp/test_codex_#{SecureRandom.alphanumeric}"
    f = @codex.save_file(fpath)

    expect(f).to be_a(File)
    expect(File.exist?(f.path)).to be(true)
    expect(LilBlaster::Codex.new(path: fpath).remote_name).to eq(@codex.remote_name)
  end

  it 'can determine whether a symbol is known to it' do
    expect(@codex.key?(:power)).to be(true)
    expect(@codex.key?(:nonexistent)).to be(false)
  end

  it 'can generate a transmission for each symbol it knows' do
    @codex.each_key do |ky|
      expect(@codex.call(ky)).to be_a(LilBlaster::Transmission)
    end
  end

  it 'can create a YAML version of itself' do
    yml = @codex.to_yaml
    hsh = Psych.load(yml)

    expect(yml).to be_a(String)
    expect(hsh).to be_a(Hash)

    expect(hsh).to have_key(:metadata)
    expect(hsh).to have_key(:codes)
  end

  it 'can create a new instance with a symbol, instance, or class for protocol' do
    proto_inst = @codex.protocol
    proto_class = proto_inst.class
    proto_sym = proto_class.to_sym
    proto_opts = proto_inst.export_options.map do |eop|
      [eop, proto_inst.send(eop)]
    end.to_h

    inst_ex = LilBlaster::Codex.new(protocol: proto_inst)

    class_ex = LilBlaster::Codex.new(
      protocol: proto_class,
      protocol_options: proto_opts
    )

    sym_ex = LilBlaster::Codex.new(protocol: proto_sym, protocol_options: proto_opts)

    expect(inst_ex.protocol).to eq(@codex.protocol)
    expect(class_ex.protocol).to be_a(proto_class)
    expect(sym_ex.protocol.to_sym).to eq(proto_sym)
  end
end
