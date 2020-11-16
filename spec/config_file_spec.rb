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

      LilBlaster::ConfigFile.config.location_paths.clear
      LilBlaster::ConfigFile.config.append_path(@temp_dir)
    end

    after :each do
      FileUtils.remove_entry @temp_dir
    end

    it 'can set pins with the config file' do
      old = LilBlaster.reader_pin, LilBlaster.transmitter_pin

      LilBlaster::ConfigFile[:reader_pin] = 99
      LilBlaster::ConfigFile[:transmitter_pin] = 42

      expect(LilBlaster.reader_pin).to eq(99)
      expect(LilBlaster.transmitter_pin).to eq(42)

      LilBlaster.reader_pin = old[0]
      LilBlaster.transmitter_pin = old[1]
    end

    describe 'without an existing file' do
      it 'can save out successfully' do
        fp = [@temp_dir, 'lil_blaster_config.yml'].join('/')
        LilBlaster::ConfigFile.save

        expect(File.exist?(fp))
      end
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

      describe 'with codexes folder' do
        it 'can autoload present codexes' do
          fpath = "#{@codex_dir}/#{SecureRandom.alphanumeric}_codex.yml"
          File.open(fpath, 'w+') { |f| f << @codex_yaml }

          expect(LilBlaster::Codex.autoload).not_to be_empty
        end

        it 'returns a blank if no codexes are present' do
          expect(LilBlaster::Codex.autoload).to be_empty
        end

        it 'returns a blank if no codex dir is specified' do
          LilBlaster::ConfigFile.delete(:codexes_dir)

          expect(LilBlaster::ConfigFile[:codexes_dir]).to be_nil
          expect(LilBlaster::Codex.autoload).to be_empty
        end
      end
    end
  end
end
