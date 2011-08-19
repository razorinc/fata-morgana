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

desc "install openshift-cartridge-*"
task :install_openshift_cartridges do
    sh "yum -y install openshift-cartridge-\*"
end

desc "remove openshift-cartridge-*"
task :remove_openshift_cartridges do
    sh "yum -y remove openshift-cartridge-\*"
end

desc "Generate repo from all opm templates in test/data/"
task :create_local_repo do
    repo_dir = Dir.pwd
    for opm_dir in Dir.glob("#{repo_dir}/test/data/*") do
        mkdir_p "/var/tmp/rpms"
        cd "/var/tmp/rpms"
        sh "opm control-to-spec #{opm_dir}"
        sh "opm create-rpm #{opm_dir}"
    end
    for rpm in Dir.glob("*.rpm") do
        sh "opm add-to-repo #{rpm}"
    end
    cd repo_dir
end

desc "Unit tests"
Rake::TestTask.new("test") do |t|
  t.libs << File.expand_path('../lib', __FILE__)
  t.libs << File.expand_path('../test', __FILE__)
  t.libs << File.expand_path('../test/unit', __FILE__)
  t.pattern = 'test/unit/**/*_test.rb'
end

desc "Run all tests"
task :run_all_tests => [:remove_openshift_cartridges, :clean_old_repo, :create_local_repo] do
    sh "rm -rf /var/tmp/openshift.db"
    cd "test"
    sh "ruby all_tests.rb"
end
