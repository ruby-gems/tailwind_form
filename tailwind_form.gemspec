require_relative "lib/tailwind_form/version"

Gem::Specification.new do |spec|
  spec.name = "tailwind_form"
  spec.version = TailwindForm::VERSION
  spec.authors = ["doabit"]
  spec.email = ["doinsist@gmail.com"]
  spec.homepage = "https://github.com/ruby-gems/tailwind_form"
  spec.summary = "TailwindForm engine"
  spec.description = "TailwindForm engine"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.0"
end
