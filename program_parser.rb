
# Monologue program dump format:
# https://www.korg.com/us/support/download/manual/0/733/4231/
# https://cdn.korg.com/us/support/download/files/16ee9047b932f624ed640d98940ff798.txt?response-content-disposition=attachment%3Bfilename%2A%3DUTF-8%27%27monologue_MIDIimp.txt&response-content-type=application%2Foctet-stream%3B

# MIDI data must be encoded in 7-bit bytes
# (most significat bit is used to mark STATUS bytes)
# Korg Monologue encodes data in 7-byte chunks
def midi_encoder(bytes)
  raise "Invalid data length #{bytes.size}" unless bytes.size % 7 == 0
  result = []
  (0...bytes.size).step(7).each do |start|
    chunk = bytes[start, 7]
    msbits = 0
    chunk.each_with_index do |b, i|
      msbits |= (b & 0x80) >> (7 - i)
    end
    result << msbits
    result += chunk.map{|b| b & 0x7F}
  end
  result
end

def midi_decoder(bytes)
  raise "Invalid data length #{bytes.size}" unless bytes.size % 8 == 0
  result = []
  (0...bytes.size).step(8).each do |start|
    msbits = bytes[start]
    chunk = bytes[start + 1, 7]
    chunk.each_with_index do |b, i|
      result << (b | ((msbits & 1) << 7))
      msbits >>= 1
    end
  end
  result
end

def to_bytes(str)
  str.bytes
end

def from_bytes(bytes)
  bytes.pack('c*')
end

def hex(str)
  str.unpack("H*").first
end

# Extract program data dump from midi message
def get_program_midi_data(data)
  valid = data[0] == 0xF0 &&
    data[1] == 0x42 &&
    (data[2] & 0xF0 == 0x30) &&
    data[3] == 0x00 &&
    data[4] == 0x01 &&
    data[5] == 0x44 &&
    (data[6] == 0x4C || data[6] == 0x40) &&
    data[-1] == 0xF7
  if data[6] == 0x40
    # current program
    program = nil
    start = 7
  else
    program = data[7]
    start = 9
  end
  prog = data[start...-1]
  raise "Invalid program" unless valid && prog.size == 512
  from_bytes midi_decoder prog
end

# Extract program data dump from binary file
# (like the .prog_bin files that are part of .molglib/.molgpreset packs)
def get_program_file_data(program_file)
  File.open(program_file,'rb'){|f| f.read}
end

# Extract program name from program data dump
def program_name(prog)
  name = prog[4...16]
  while name.chomp!("\0")
  end
  name
end

CONVERTERS = {
  cents: ->(value) {
    # TODO: adjust: this doesn't seem to be really piece-wise linear
    if value < 4
      -1200
    elsif value < 306
      -1200 + ((value - 4)*(1200-256)/(306.0-4)).round
    elsif value < 463
      -256 + ((value - 306)*(256-16)/(463.0-356)).round
    elsif value < 492
      -16 + ((value - 463)*(256-16)/(463.0-356)).round
    elsif value < 532
      0
    elsif value < 561
      ((value - 532)*(16)/(564.0-532)).round
    elsif value < 718
      16 + ((value - 564)*(256-16)/(718.0-564)).round
    elsif value < 1020
      256 + ((value - 718)*(1200-256)/(1020.0-718)).round
    else
      1200
    end
  },
  shape1: {
    0 => 'SQR',
    1 => 'TRI',
    2 => 'SAW'
  },
  shape2: {
    0 => 'NOISE',
    1 => 'TRI',
    2 => 'SAW'
  },
  sync_ring: {
    0 => 'RING',
    1 => 'OFF',
    2 => 'SYNC'
  },
  bpm: ->(value) {
    case value
    when 0..63
      '4'
    when 64..127
      '2'
    when 128..191
      '1'
    when 192..255
      '3/4'
    when 256..319
      '1/2'
    when 320..383
      '3/8'
    when 384..447
      '1/3'
    when 448..511
      '1/4'
    when 512..575
      '3/16'
    when 576..639
      '1/6'
    when 640..703
      '1/8'
    when 704..767
      '1/12'
    when 768..831
      '1/16'
    when 832..895
      '1/24'
    when 896..959
      '1/32'
    when 960..1023
      '1/36'
    end
  },
  octave: {
    0 => "16'",
    1 => "8'",
    2 => "4'",
    3 => "2'"
  },
  keyb_octave: ->(v) { v - 2 },
  eg_type: {
    0 => 'GATE',
    1 => 'A/G/D',
    2 => 'A/D'
  },
  eg_target: {
    0 => 'CUTOFF',
    1 => 'PITCH 2',
    2 => 'PITCH'
  },
  lfo_mode: {
    0 => '1-SHOT',
    1 => 'SLOW',
    2 => 'FAST'
  },
  lfo_target: {
    0 => 'CUTOFF',
    1 => 'SHAPE',
    2 => 'PITCH'
  },
  switch: {
    0 => 'OFF',
    1 => 'ON'
  },
  program_cents: ->(v) { v - 50 },
  micro_tuning: {
      0 => 'Equal Temp',
      1 => 'Pure Major',
      2 => 'Pure Minor',
      3 => 'Pythagorean',
      4 => 'Werckmeister',
      5 => 'Kirnburger',
      6 => 'Slendro',
      7 => 'Pelog',
      8 => 'Ionian',
      9 => 'Dorian',
     10 => 'Aeolian',
     11 => 'Major Penta',
     12 => 'Minor Penta',
     13 => 'Reverse',
     14 => 'AFX001',
     15 => 'AFX002',
     16 => 'AFX003',
     17 => 'AFX004',
     18 => 'AFX005',
     19 => 'AFX006',
    128 => 'USER SCALE 1',
    129 => 'USER SCALE 2',
    130 => 'USER SCALE 3',
    131 => 'USER SCALE 4',
    132 => 'USER SCALE 5',
    133 => 'USER SCALE 6',
    134 => 'USER OCTAVE 1',
    135 => 'USER OCTAVE 2',
    136 => 'USER OCTAVE 3',
    137 => 'USER OCTAVE 4',
    138 => 'USER OCTAVE 5',
    139 => 'USER OCTAVE 6'
  },
  scale_key: ->(v) { v - 12 },
  slide_time: ->(v) { (v*100.0/72).round },
  portament_time: ->(v) { v == 0 ? 'OFF' : v - 1 },
  slider_assign: {
    13 => 'VCO 1 PITCH',
    14 => 'VCO 1 SHAPE',
    17 => 'VCO 2 PITCH',
    18 => 'VCO 2 SHAPE',
    21 => 'VCO 1 LEVEL',
    22 => 'VCO 1 LEVEL',
    23 => 'CUTOFF',
    24 => 'RESONANCE',
    26 => 'ATTACK',
    27 => 'DECAY',
    28 => 'EG INT',
    31 => 'LFO RATE',
    32 => 'LFO INT',
    40 => 'PORTAMENT',
    56 => 'PITCH BEND',
    57 => 'GATE TIME'
  },
  identity: ->(v) { v },
  portament_mode: {
    0 => 'AUTO',
    1 => 'ON'
  },
  three_pct: {
    0 => '0%',
    1 => '50%',
    2 => '100%'
  },
  program_level: ->(v) { v - 77 - 25 },
  signed: ->(v) { v - 512 }
}

HR_PARAMS = [
  [:vco1_pitch, 16, 30, 0, :cents],
  [:vco1_shape, 17, 30, 2],
  [:vco2_pitch, 18, 31, 0, :cents],
  [:vco2_shape, 19, 31, 2],
  [:vco1_level, 20, 33, 0],
  [:vco2_level, 21, 33, 2],
  [:cutoff, 22, 33, 4],
  [:resonance, 23, 33, 6],
  [:eg_attack, 24, 34, 2],
  [:eg_decay, 25, 34, 4],
  [:eg_int, 26, 35, 0, :signed],
  [:lfo_rate, 27, 35, 2, :bpm],
  [:lfo_int, 28, 35, 4, :signed],
  [:drive, 29, 35, 6]
]

# TODO: eg_int, lfo_int
# values 512-1023 are positive corresponding to knob minPos (512) to maxPos (1023)
# values 0-511 are negative corresponding to shift+knob maxPos (0) to minPos (512)
# represent the knob position properly + the shifted state

CONV_PARAMS = [
  [:vco1_octave, 30, 4, 2, :octave],
  [:vco2_octave, 31, 4, 2, :octave],
  [:vco1_wave, 30, 6, 2, :shape1],
  [:vco2_wave, 31, 6, 2, :shape2],
  [:sync_ring, 32, 0, 2, :sync_ring],
  [:keyb_octave, 32, 2, 3, :keyb_octave],
  [:eg_type, 34, 0, 2, :eg_type],
  [:eg_target, 34, 6, 2, :eg_target],
  [:lfo_type, 36, 0, 2, :shape1],
  [:lfo_mode, 36, 2, 2, :lfo_mode],
  [:lfo_target, 36, 4, 2, :lfo_target],
  [:seq_trig, 36, 6, 1, :switch],
  [:program_tuning, 37, 0, 7, :program_cents],
  [:micro_tuning, 38, 0, 7, :micro_tuning],
  [:scale_key, 39, 0, 7, :scale_key],
  [:slide_time, 40, 0, 7, :slide_time],
  [:portament_time, 41, 0, 7, :portament_time],
  [:slider_assign, 42, 0, 7, :slider_assign],
  [:bend_range_pos, 43, 0, 4, :identity],
  [:bend_range_neg, 43, 4, 4, :identity],
  [:portament_mode, 44, 0, 1, :portament_mode],
  [:lfo_bpm_sync, 44, 3, 1, :switch],
  [:cutoff_velocity, 44, 4, 2, :three_pct],
  [:cutoff_keytrack, 44, 6, 2, :three_pct],
  [:program_level, 45, 0, 7, :program_level],
  [:amp_velocity, 46, 0, 7, :identity],
]

def bits(byte, pos, len)
  (byte >> pos) & ((1 << len) - 1)
end

# Parse program data dump
def parse_program(prog)
  prog_bytes = to_bytes(prog)
  data = {}
  raise "Invalid program" unless prog[0, 4] == 'PROG'
  name = prog[4...16]
  data[:name] = program_name(prog)

  HR_PARAMS.each do |(key, ms_offset, ls_offset, ls_pos, units)|
    # single byte value
    value = prog_bytes[ms_offset]
    data[key] = value
    # high resolution value
    value_hr = (value << 2) | ((prog_bytes[ls_offset] >> ls_pos) & 0x03)
    data[:"#{key}_hr"] = value_hr
    if units
      # converted value:
      data[:"#{key}_#{units}"] = CONVERTERS[units][value_hr]
    end
  end

  CONV_PARAMS.each do |(key, offset, bit_pos, bit_len, units)|
    value = bits(prog_bytes[offset], bit_pos, bit_len)
    data[key] = CONVERTERS[units][value]
    if value != data[key]
      data[:"#{key}_value"] = value
    end
  end

  data[:lfo_rate_vis] = data[:lfo_bpm_sync] == 'ON' ? data[:lfo_rate_bpm] : data[:lfo_rate_hr]
  data[:eg_int_abs] = data[:eg_int_signed].abs
  data[:lfo_int_abs] = data[:lfo_int_signed].abs
  data
end
