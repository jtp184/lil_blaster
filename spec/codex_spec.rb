RSpec.describe LilBlaster::Codex do
  before :all do
    @codex_yaml = FactoryBot.fixtures[:codex_yaml]
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

  it 'can handle codes which are numeric, array, or Transmission' do
    cdx = FactoryBot.build(:codex)
    cdx.codes[:transmission] = FactoryBot.build(:transmission)
    cdx.codes[:array] = [cdx[:power], cdx[:power]]
    cdx.codes[:standard] = cdx[:power]

    %i[transmission array standard].each do |sym|
      expect(cdx.call(sym)).to be_a(LilBlaster::Transmission)
    end

    expect(cdx.call(:transmission).data).to eq(FactoryBot.build(:transmission).data)
    expect(cdx.call(:array).count).to eq(cdx.call(:power).count * 2)
  end

  describe 'appending data' do
    before :each do
      @codex = FactoryBot.build(:codex)
    end

    it 'can append data values to itself' do
      @codex.append(data: 0x1234, as: :newval)

      expect(@codex[:newval]).to eq(0x1234)
    end

    it 'can append decodable transmission values to itself' do
      @codex.append(transmission: FactoryBot.build(:transmission), key: :newval)

      expect(@codex[:newval]).to eq(0x40bf)
    end

    it 'can infer its own protocol from transmissions' do
      @codex.protocol = nil

      @codex.append(transmission: FactoryBot.build(:transmission), key: :newval)

      expect(@codex[:newval]).to eq(0x40bf)
      expect(@codex.protocol).not_to be_nil
      expect(@codex.protocol).to be_a(LilBlaster::Protocol::Manchester)
    end

    it 'can append raw transmission values to itself' do
      @codex.append(raw_transmission: FactoryBot.build(:transmission), key: :newval)

      expect(@codex[:newval]).to be_a(LilBlaster::Transmission)
      expect(@codex[:newval].data).to eq(FactoryBot.build(:transmission).data)
    end

    it 'can append undecodable transmission values to itself' do
      @codex.append(
        transmission: LilBlaster::Transmission.new(data: Array.new(12, 500)),
        as: :newval
      )

      expect(@codex[:newval]).to be_a(LilBlaster::Transmission)
    end
  end
end
