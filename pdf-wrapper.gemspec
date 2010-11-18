Gem::Specification.new do |spec|
  spec.name = "pdf-wrapper"
  spec.version = "0.4.3"
  spec.summary = "A PDF generating library built on top of cairo"
  spec.description = "A unicode aware PDF writing library that uses the ruby bindings to various c libraries ( like cairo, pango, poppler and rsvg ) to do the heavy lifting."
  spec.files =  Dir.glob("{examples,lib}/**/*") + ["Rakefile"]
  spec.test_files =  Dir.glob("spec/**/*") + ["Rakefile"]
  spec.has_rdoc = true
  spec.extra_rdoc_files = %w{README.rdoc CHANGELOG TODO}
  spec.rdoc_options << '--title' << 'PDF::Wrapper Documentation' << '--main'  << 'README.rdoc' << '-q'
  spec.author = "James Healy"
  spec.homepage = "https://github.com/yob/pdf-wrapper"
  spec.email = "jimmy@deefa.com"

  spec.add_development_dependency("rake")
  spec.add_development_dependency("roodi")
  spec.add_development_dependency("rspec", "~>2.1")
  spec.add_development_dependency("pdf-reader", "~> 0.8.6")

  spec.add_dependency("cairo", "~>1.8")
  spec.add_dependency("gtk2", "~> 0.90.5")
  spec.add_dependency("glib2", "~> 0.90.5")
  spec.add_dependency("pango", "~> 0.90.5")
  spec.add_dependency("poppler", "~> 0.90.5")
  spec.add_dependency("gdk_pixbuf2", "~> 0.90.5")
  spec.add_dependency("rsvg2", "~> 0.90.5")
end
