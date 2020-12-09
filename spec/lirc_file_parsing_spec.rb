RSpec.describe 'LIRC File parsing' do
  before :all do
    @lirc_conf = FactoryBot.fixtures[:lirc_conf]
  end

  it 'can read a valid lircd.conf file' do
    codex = LilBlaster::LircConfReader.call(@lirc_conf)

    expect(codex).to be_a(LilBlaster::Codex)
    expect(codex.keys).to include(:power)
    expect(codex.protocol.pulse_values[:header]).to eq([4633, 4321])
  end

  describe 'with a present lircd.conf file' do
    before :each do
      @temp_dir = Dir.mktmpdir("lil_blaster_test_#{Time.now.to_i}")
      @codex_dir = [@temp_dir, 'codexes'].join('/').tap { |dr| FileUtils.mkdir(dr) }
      @lirc_file_path = [@codex_dir, 'example.lircd.conf'].join('/')
      @config_path = [@temp_dir, 'lil_blaster_config.yml'].join('/')
      @config_yaml = "---\ncodexes_dir: #{@codex_dir}"

      File.open(@config_path, 'w+') { |f| f << @config_yaml }
      File.open(@lirc_file_path, 'w+') { |f| f << @lirc_conf }

      LilBlaster::ConfigFile.config.location_paths.clear
      LilBlaster::ConfigFile.config.append_path(@temp_dir)

      LilBlaster::ConfigFile.config
                            .instance_variable_get(:@settings)
                            .clear

      LilBlaster::ConfigFile.reload
    end

    after :each do
      FileUtils.remove_entry @temp_dir
    end

    it 'can autoload lircd.conf files' do
      codexes = LilBlaster::Codex.autoload!

      expect(codexes).not_to be_empty
      expect(codexes.first).to be_a(LilBlaster::Codex)
      expect(codexes.first.remote_name).to eq('Samsung_BN59-00865A')
      expect(codexes.first.protocol.pulse_values[:header]).to eq([4633, 4321])
    end
  end
end
