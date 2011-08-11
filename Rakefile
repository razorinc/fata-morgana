require 'rubygems'
require 'rake'
require 'rake/clean'

desc "Print environment to run from checkout - eval $( rake local_env | tail -n +2 )"
task :local_env do
    pwd = Dir.pwd
    puts "RUBYLIB='#{pwd}/lib/'; export RUBYLIB"
    puts "PATH='#{pwd}/bin/:#{ENV['PATH']}'; export PATH"
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

desc "Run all tests"
task :run_all_tests => [:create_local_repo] do
    cd "tests"
    sh "ruby all_tests.rb"
end
