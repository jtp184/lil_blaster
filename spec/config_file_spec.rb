RSpec.describe LilBlaster::ConfigFile do
  it 'can store config settings' do
    val = SecureRandom.alphanumeric

    LilBlaster::ConfigFile[:new_setting] = val

    expect(LilBlaster::ConfigFile[:new_setting]).to eq(val)
    LilBlaster::ConfigFile.delete(:new_setting)
  end

  it 'can retrieve config settings' do
    expect(LilBlaster::ConfigFile[:codexes_dir]).not_to be_nil
  end

  describe 'saving and loading' do
    before :each do
      @temp_dir = Dir.mktmpdir("lil_blaster_test_#{Time.now}")
      @codex_dir = [@temp_dir, 'codexes'].join('/').tap { |dr| FileUtils.mkdir(dr) }
      @config_yaml = <<~DOC
        ---
        codexes_dir: #{@codex_dir}
      DOC

      LilBlaster::ConfigFile.config.location_paths.clear
      LilBlaster::ConfigFile.config.append_path(@temp_dir)
    end

    after :each do
      FileUtils.remove_entry @temp_dir
    end

    describe 'with an existing file' do
      before :each do
        @config_path = [@temp_dir, 'lil_blaster_config.yml'].join('/')
        File.open(@config_path, 'w+') { |f| f << @config_yaml }
        LilBlaster::ConfigFile.config.read
      end

      it 'can load a file that exists in its load path' do
        expect(LilBlaster::ConfigFile.config).to be_a(TTY::Config)
        expect(LilBlaster::ConfigFile.path).to eq(@config_path)
      end

      it 'knows the path of an existent file' do
        expect(LilBlaster::ConfigFile.path).to eq(@config_path)
      end

      it 'can save the file out with changes' do
        key, val = Array.new(2) { SecureRandom.alphanumeric }

        LilBlaster::ConfigFile[key] = val
        LilBlaster::ConfigFile.save

        LilBlaster::ConfigFile.read

        expect(LilBlaster::ConfigFile[key]).to eq(val)
        expect(File.read(@config_path)).to match(/#{key}: #{val}/)
      end
    end
  end
end
