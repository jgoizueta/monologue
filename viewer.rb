require 'liquid'
require 'cgi'

def settings_panel_html(program)
  template = Liquid::Template.parse(File.read('viewer/settings_template.html'))
  params = program.inject({}){|memo,(k,v)| memo[k.to_s] = CGI.escapeHTML(v.to_s); memo}
  # TODO: sanitize params (e.g. > -> &gt;)
  template.render(params)
end

def gen_viewer(filename, *programs)
  file_path = File.join('viewer', filename)
  panels = programs.map{|p| settings_panel_html(p)}.join("\n")
  html = File.read('viewer/viewer_template.html')
  html.gsub! '{{settings}}', panels
  File.open(file_path, 'w') do |out|
    out.puts html
  end
  file_path
end

def view(*programs)
  file = gen_viewer('index.html', *programs)
  `open "#{file}"`
end
