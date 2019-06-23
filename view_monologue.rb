require 'fileutils'
require 'unimidi'
require_relative 'midi_dump'
require_relative 'program_parser'
require_relative 'viewer'

# view_monologue source prognum1, prognum2, ...
# source can be a molgpreset, a molglib file or "midi" for connecting via MIDI to the synth
# `molgpreset midi` will show the current program settings in the synth

programs = nil

file = ARGV.shift

if file == 'midi'
  prog_nums = ARGV.map{|p| p.to_i}

  UniMIDI::Input.all.select{|i| i.name == 'KORG INC. monologue'}.last.open do |input|
    UniMIDI::Output.all.select{|i| i.name == 'KORG INC. monologue'}.last.open do |output|
      if prog_nums.size == 0
        # Current Program
        programs = [current_program(input, output)]
      else
        programs = prog_nums.map{|p| program(p, input, output)}
      end
    end
  end

  view *progs.map{|p| parse_program p}

else
  tmp_dir = 'molg_tmp'
  FileUtils.mkdir_p tmp_dir
  `unzip "#{file}" -d #{tmp_dir}`

  def pad(n, l=3)
    n = n.to_s
    if n.size < l
      n = "0"*(l - n.size) + n
    end
    n
  end

  prog_nums = ARGV
  if prog_nums.size == 0
    # TODO: use FileInformation.xml/PresetInformation.xml?
    prog_files = Dir[File.join(tmp_dir, 'Prog_*.prog_bin')].sort
  else
    prog_files = prog_nums.map{|n| File.join(tmp_dir, "Prog_#{pad(n)}.prog_bin")}
  end

  programs = prog_files.map{|f| get_program_file_data(f)}

  FileUtils.rm_rf File.join(tmp_dir)
end

view *programs.map{|program| parse_program program}
