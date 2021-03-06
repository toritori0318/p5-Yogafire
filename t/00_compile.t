use strict;
use warnings;
use Test::More;

use Yogafire;

BEGIN {
    use_ok ("Yogafire::ActionBase");
    use_ok ("Yogafire::Command::Common::config");
    use_ok ("Yogafire::Command::Common::use");
    use_ok ("Yogafire::Command::Image::lsami");
    use_ok ("Yogafire::Command::Instance::changeinstancetype");
    use_ok ("Yogafire::Command::Instance::cmd");
    use_ok ("Yogafire::Command::Instance::createimage");
    use_ok ("Yogafire::Command::Instance::expandvolume");
    use_ok ("Yogafire::Command::Instance::get");
    use_ok ("Yogafire::Command::Instance::getnoopt");
    use_ok ("Yogafire::Command::Instance::info");
    use_ok ("Yogafire::Command::Instance::ls");
    use_ok ("Yogafire::Command::Instance::put");
    use_ok ("Yogafire::Command::Instance::putnoopt");
    use_ok ("Yogafire::Command::Instance::reboot");
    use_ok ("Yogafire::Command::Instance::ssh");
    use_ok ("Yogafire::Command::Instance::start");
    use_ok ("Yogafire::Command::Instance::stop");
    use_ok ("Yogafire::Command::Instance::terminate");
    use_ok ("Yogafire::Command::Plugin::allregioninfo");
    use_ok ("Yogafire::Command::Plugin::amiwatcher");
    use_ok ("Yogafire::Command::Plugin::awsstatus");
    use_ok ("Yogafire::Command::Plugin::ec2watcher");
    use_ok ("Yogafire::Command::Plugin::hosts");
    use_ok ("Yogafire::Command::Plugin::instancetype");
    use_ok ("Yogafire::Command::Plugin::region");
    use_ok ("Yogafire::Command::Plugin::render");
    use_ok ("Yogafire::Command::Plugin::sshconfig");
    use_ok ("Yogafire::Command::Plugin::updateec2tags");
    use_ok ("Yogafire::Command::Vpc::vpcgraph");
    use_ok ("Yogafire::Command::Vpc::vpcinfo");
    use_ok ("Yogafire::CommandBase");
    use_ok ("Yogafire::CommandClass::ImageProc");
    use_ok ("Yogafire::CommandClass::InstanceProc");
    use_ok ("Yogafire::CommandClass::SSH");
    use_ok ("Yogafire::CommandClass::Sync");
    use_ok ("Yogafire::Config");
    use_ok ("Yogafire::Image::Action::Deregister");
    use_ok ("Yogafire::Image::Action::Info");
    use_ok ("Yogafire::Image::Action::RunInstances");
    use_ok ("Yogafire::Image::Action");
    use_ok ("Yogafire::Image");
    use_ok ("Yogafire::Instance::Action::ChangeInstanceType");
    use_ok ("Yogafire::Instance::Action::CopyAndLaunch");
    use_ok ("Yogafire::Instance::Action::CreateImage");
    use_ok ("Yogafire::Instance::Action::ExtendVolume");
    use_ok ("Yogafire::Instance::Action::Info");
    use_ok ("Yogafire::Instance::Action::Quit");
    use_ok ("Yogafire::Instance::Action::Reboot");
    use_ok ("Yogafire::Instance::Action::SSH");
    use_ok ("Yogafire::Instance::Action::Start");
    use_ok ("Yogafire::Instance::Action::Stop");
    use_ok ("Yogafire::Instance::Action::Terminate");
    use_ok ("Yogafire::Instance::Action");
    use_ok ("Yogafire::Instance");
    use_ok ("Yogafire::InstanceTypes");
    use_ok ("Yogafire::Logger");
    use_ok ("Yogafire::Output::Table");
    use_ok ("Yogafire::Output");
    use_ok ("Yogafire::Regions");
    use_ok ("Yogafire::Term");
    use_ok ("Yogafire::Util");
    use_ok ("Yogafire::Vpc::Action::Graph");
    use_ok ("Yogafire::Vpc::Action::Info");
    use_ok ("Yogafire::Vpc::Action");
    use_ok ("Yogafire::Vpc");
    use_ok ("Yogafire");
};

done_testing;

