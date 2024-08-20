require 'rake/clean'

CLEAN.include %w[**.rbc rdoc coverage]

desc 'Do a full cleaning'
task :distclean do
  CLEAN.include %w[tmp pkg sequel_foreign_key_list_caching*.gem lib/*.so]
  Rake::Task[:clean].invoke
end

desc 'Build the gem'
task :gem do
  sh %(gem build sequel_foreign_key_list_caching.gemspec)
end

begin
  require 'rake/extensiontask'
  Rake::ExtensionTask.new('sequel_foreign_key_list_caching')
rescue LoadError
end
