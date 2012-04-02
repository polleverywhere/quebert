# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "quebert/version"

Gem::Specification.new do |s|
  s.name        = "quebert"
  s.version     = Quebert::VERSION
  s.authors     = ["Brad Gessler", "Steel Fu", "Jeff Vyduna"]
  s.email       = ["brad@bradgessler.com"]
  s.homepage    = "http://github.com/polleverywhere/quebert"
  s.summary     = %q{A worker queue framework built around beanstalkd}
  s.description = %q{A worker queue framework built around beanstalkd}

  s.rubyforge_project = "quebert"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "json"
  s.add_runtime_dependency "beanstalk-client"
  
  s.add_development_dependency 'rspec', '2.7.0'
end