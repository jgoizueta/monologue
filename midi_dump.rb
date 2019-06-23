# Methods to read Korg Monologue configuration (program dumps, global data) via MIDI

require 'unimidi'

def responses(input)
  # input.gets.map{|m| m[:data]}.reject{|d| d == [0xF8]}.flatten
  input.gets.map{|m| m[:data]}.reject{|d| d == [0xF8]}
end

def response(input)
  response(input).flatten
end

def is_status(byte)
  !!(byte & 0x80)
end

def is_sysrt(byte)
  [0xF8, 0xFA, 0xFB, 0xFC, 0xFE, 0xFF].include? byte
end

def filter_sysrt(bytes)
  bytes.reject{|b| is_sysrt(b)}
end

SYSEX_START = 0xF0
SYSEX_EDN   = 0xF7

def wait_sysex_response(input)
  sleep 0.3
  r = []
  # UniMIDI behaviour is weird when using gets: after separate parts of
  # a long message, the whole sysex message appears; segfault can occur occasionally too
  while r.size == 0 || r.last&.last != 0xF7
    d = responses(input)
    if d.size > 0
      r += d
      d.each do |part|
        if part.first == SYSEX_START && part.last == SYSEX_EDN
          r = [part]
          break
        end
      end
    end
  end
  r = filter_sysrt r.flatten
  raise "Invalid sysex" if r[1...-1].any?{|b| is_sysrt(b)}
  r
end

def flush(input)
  input.clear_buffer
  input.gets
end

def device_inquiry(input, output, channel = 0)
  flush input
  output.puts [0xF0, 0x7E, channel, 0x06, 0x01, 0xF7]
  wait_sysex_response input
end

def global_data(input, output, channel = 0)
  flush input
  output.puts [0xF0, 0x42, 0x30+channel, 0x00, 0x01, 0x44, 0x0E, 0xF7]
  wait_sysex_response input
end

def current_program(input, output, channel = 0)
  flush input
  output.puts [0xF0, 0x42, 0x30+channel, 0x00, 0x01, 0x44, 0x10, 0xF7]
  wait_sysex_response input
end

def program(num_prog, input, output, channel = 0)
  flush input
  output.puts [0xF0, 0x42, 0x30+channel, 0x00, 0x01, 0x44, 0x1C, num_prog, 0x00, 0xF7]
  wait_sysex_response input
end

# def fmt(data)
#   data.map{|d| '>> ' +  d.map{|v| v.to_s(16)}*' '}*"\n"
# end

# UniMIDI::Input.all.select{|i| i.name == 'KORG INC. monologue'}.last.open do |input|
#   UniMIDI::Output.all.select{|i| i.name == 'KORG INC. monologue'}.last.open do |output|
#     puts "# Current Program"
#     p = current_program(input, output)
#     puts p.size
#     puts p.inspect
#     for prog in (0...10)
#       puts "# Program #{prog}"
#       p = program(prog, input, output)
#       puts p.size
#       puts p.inspect
#     end
#   end
# end