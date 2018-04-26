require 'erb'
require 'pathname'

project_root = Pathname(__dir__).join("..", "..")
template = project_root.join(".env.example")
destination = project_root.join(".env")

result = ERB.new(template.read).result(binding)

puts <<-PREVIEW
--------[.env]--------
#{result}
----------------------
PREVIEW

destination.write(result)
