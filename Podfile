#
# The following environment variables are optional for you to control your build:
# AYLA_BUILD_BRANCH: default to the current branch
# AYLA_SDK_BRANCH: default to AYLA_BUILD_BRANCH
#
# if you want to build a branch other than your crrent branch, switch to that branch to build it;
# for public release we set lib branch by replacing $AYLA_BUILD_BRANCH with release/4.4.00 etc because
# their branch names are different; for internal repos, lib branches can be the same as build branch
# such as "develop" etc
#
# The following are for rare cases when you use a git protocol other than https or a different remote
# AYLA_PUBLIC: "" for internal, "_Public" for public repo, script can detect by itself unless you specify
# AYLA_SDK_REPO: default to https://github.com/AylaNetworks/iOS_AylaSDK(_Public).git
# AYLA_REMOTE: default to origin
#
require_relative './Podhelper'

#Configuration Section: you can change the following variables to configure your build
conditional_assign("ayla_build_branch", "") #"release/4.4.0"
conditional_assign("ayla_sdk_branch", "release/5.1.00") #or @ayla_build_branch)
conditional_assign("ayla_sdk_repo", "") #"https://github.com/AylaNetworks/iOS_AylaSDK(_Public).git"
conditional_assign("ayla_public", "")
conditional_assign("ayla_remote", "origin")

# conext display: show value whenever related environment variables are set
build_var_array=["AYLA_BUILD_BRANCH", "AYLA_SDK_BRANCH", "AYLA_SDK_REPO", "AYLA_PUBLIC", "AYLA_REMOTE"]
build_var_array.each do |n|
    puts "Your #{n} is set to #{ENV[n]}" if ENV.has_key?(n) and !ENV[n].empty?;
end

branch_string=`git branch | grep "* "`
abort "No branch found." if $?.to_i != 0

cur_branch=branch_string.split(' ')[-1]

# default all branches to the current branch if they are still not set or empty
conditional_assign("ayla_build_branch", cur_branch)
conditional_assign("ayla_sdk_branch", cur_branch)

cur_path=File.expand_path('.')
public_repo_path_pattern=/.*_Public$/
if public_repo_path_pattern =~ cur_path
    conditional_assign("ayla_public", "_Public")
    repo_type="public"
else
    repo_type="internal"
end
conditional_assign "ayla_sdk_repo", "https://github.com/AylaNetworks/iOS_AylaSDK#{@ayla_public}.git"

puts "\n*** Building #{repo_type.try(:green)} repo on branch #{@ayla_build_branch.try(:green)} with sdk branch #{@ayla_sdk_branch.try(:green)} ***"
puts "*** sdk repo: #{@ayla_sdk_repo.try(:green)} ***\n\n"

build_var_array.each do |v|
    puts "now #{v} = " + instance_variable_get("@#{v.downcase}").to_s
end

source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.4'

use_frameworks!

target :iOS_Aura do
    pod 'iOS_AylaSDK',
    :git => "#{@ayla_sdk_repo}", :branch => "#{@ayla_sdk_branch}"
#    :path => '../iOS_AylaSDK', :branch => "#{@ayla_sdk_branch}"
    pod 'SwiftKeychainWrapper'
    pod 'SAMKeychain'
    pod 'PDKeychainBindingsController'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << " DD_LEGACY_MACROS=1"
  end
end
