ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup"
begin
  require "bootsnap/setup"
rescue LoadError
  # bootsnap es opcional (acelera el arranque)
end
