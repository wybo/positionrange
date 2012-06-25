# -*- encoding: utf-8 -*-
require File.expand_path('../lib/position_range/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors = ['Wybo Wiersma']
  gem.email = ['mail@wybowiersma.net']
  gem.description = 'Allows one to assign random attributes to ranges and juggle them in lists. Also adds parsing from string, but most interesting when used in a PositionRange::List. In lists standard set operations can be applied to them, like addition, substraction and intersection. In addition one can also get the combined size of all the ranges in the list. And cluster overlapping ranges, maintaining the attributes.'
  gem.summary = 'Ranges that can have dynamic attributes'
  gem.homepage = 'https://github.com/wybo/positionrange'

  gem.files = `git ls-files`.split($\)
  gem.test_files = gem.files.grep(%r{^test/test_.*})
  gem.name = 'positionrange'
  gem.require_paths = ['lib']
  gem.version = PositionRange::VERSION

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'test-unit'
  gem.add_development_dependency 'require_relative'
end
