require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'

desc "Print environment to run from checkout - eval $( rake local_env | tail -n +2 )"
task :local_env do
    pwd = Dir.pwd
    puts "RUBYLIB='#{pwd}/lib/'; export RUBYLIB"
    puts "PATH='#{pwd}/bin/:#{ENV['PATH']}'; export PATH"
end

desc "clean out old repo"
task :clean_old_repo do
    sh "yum clean all"
end

desc "remove openshift-cartridge-*"
task :remove_openshift_cartridges do
    sh "yum -y remove openshift-cartridge-\*"
end

desc "Generate repo from all vpm templates in tests/data/"
task :create_local_repo do
    repo_dir = Dir.pwd
    for vpm_dir in Dir.glob("#{repo_dir}/tests/data/*") do
        mkdir_p "/var/tmp/rpms"
        cd "/var/tmp/rpms"
        sh "vpm control-to-spec #{vpm_dir}"
        sh "vpm create-rpm #{vpm_dir}"
    end
    for rpm in Dir.glob("*.rpm") do
        sh "vpm add-to-repo #{rpm}"
    end
    cd repo_dir
end

desc "Unit tests"
Rake::TestTask.new("test") do |t|
  t.libs << File.expand_path('../lib', __FILE__)
  t.libs << File.expand_path('../tests', __FILE__)
  t.libs << File.expand_path('../tests/unit', __FILE__)
  t.pattern = 'tests/unit/**/*_test.rb'
end

desc "Run all tests"
task :run_all_tests => [:remove_openshift_cartridges, :clean_old_repo, :create_local_repo] do
    sh "rm -rf /var/tmp/vostok.db"
    cd "tests"
    sh "ruby all_tests.rb"
end
