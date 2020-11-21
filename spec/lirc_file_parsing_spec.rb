RSpec.describe 'LIRC File parsing' do
  before :all do
    @lirc_conf = <<~DOC
      #
      # this config file was automatically generated
      # using lirc-0.8.0(userspace) on Sat May  22 23:33:46 2010
      #
      # contributed by Gerard Delafond (gerard|delafond.org)
      # only modifying BN59-00516A
      #
      # brand: Samsung
      # model no. of remote control: BN59-00865A
      # devices being controlled by this remote: LE19B450C4W LCD TV
      #

      begin remote
        name Samsung_BN59-00865A
        bits           16
        flags SPACE_ENC|CONST_LENGTH
        eps            30
        aeps          100
        header       4633  4321
        one           712  1520
        zero          712   398
        ptrail        704
        pre_data_bits   16
        pre_data       0xE0E0
        gap          108193
        toggle_bit      0
            begin codes
                KEY_TV                   0xD827                    #  Was: TV
                TOOLS                    0xD22D
                KEY_FAVORITES            0x22DD                    #  Was: FAV_CH
                KEY_ENTER                0x1AE5                    #  Was: RETURN
                CH_LIST                  0xD629
                KEY_POWER                0x40BF                    #  Was: POWER
                KEY_CYCLEWINDOWS         0x807F                    #  Was: SOURCE
                KEY_1                    0x20DF                    #  Was: 1
                KEY_2                    0xA05F                    #  Was: 2
                KEY_3                    0x609F                    #  Was: 3
                KEY_4                    0x10EF                    #  Was: 4
                KEY_5                    0x906F                    #  Was: 5
                KEY_6                    0x50AF                    #  Was: 6
                KEY_7                    0x30CF                    #  Was: 7
                KEY_8                    0xB04F                    #  Was: 8
                KEY_9                    0x708F                    #  Was: 9
                KEY_0                    0x8877                    #  Was: 0
                PRE-CH                   0xC837
                KEY_VOLUMEUP             0xE01F                    #  Was: VOL+
                KEY_CHANNELUP            0x48B7                    #  Was: P+
                KEY_MUTE                 0xF00F                    #  Was: MUTE
                KEY_VOLUMEDOWN           0xD02F                    #  Was: VOL-
                KEY_CHANNELDOWN          0x08F7                    #  Was: P-
                KEY_MENU                 0x58A7                    #  Was: MENU
                KEY_EXIT                 0xB44B                    #  Was: EXIT
                KEY_UP                   0x06F9                    #  Was: UP
                KEY_LEFT                 0xA659                    #  Was: LEFT
                ENTER-OK                 0x16E9
                KEY_RIGHT                0x46B9                    #  Was: RIGHT
                KEY_DOWN                 0x8679                    #  Was: DOWN
                KEY_EPG                  0xF20D                    #  Was: GUIDE
                KEY_INFO                 0xF807                    #  Was: INFO
                TEXT-MIX                 0x34CB
                KEY_RED                  0x36C9                    #  Was: RED
                KEY_GREEN                0x28D7                    #  Was: GREEN
                KEY_YELLOW               0xA857                    #  Was: YELLOW
                KEY_BLUE                 0x6897                    #  Was: BLUE
                KEY_SUBTITLE             0xA45B                    #  Was: SUBTITLE
            end codes
      end remote
    DOC
  end

  it 'can read a valid lircd.conf file' do
    codex = LilBlaster::LircConfReader.call(@lirc_conf)

    expect(codex).to be_a(LilBlaster::Codex)
    expect(codex.keys).to include(:key_power)
    expect(codex.protocol.gap).to eq(108_193)
  end

  describe 'with a present lircd.conf file' do
    before :each do
      @temp_dir = Dir.mktmpdir("lil_blaster_test_#{Time.now.to_i}")
      @codex_dir = [@temp_dir, 'codexes'].join('/').tap { |dr| FileUtils.mkdir(dr) }
      @lirc_file_path = [@codex_dir, 'example.lircd.conf'].join('/')
      @config_path = [@temp_dir, 'lil_blaster_config.yml'].join('/')
      @config_yaml = <<~DOC
        ---
        codexes_dir: #{@codex_dir}
      DOC

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
      expect(codexes.first.protocol.gap).to eq(108_193)
    end
  end
end