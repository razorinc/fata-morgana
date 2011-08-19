OpenShift SDK Quickstart
=========================

Prereqs
-------

If you are running RHEL, make sure to have the EPEL and Optional repositories
installed.  Here is a how-to for setting up EPEL: http://johnpoelstra.com/2010/12/23/rhel-6-epel

Next, setup the repository for our internal build artifacts:
    sudo cp openshift-sdk.repo /etc/yum.repos.d/

Installing via RPM
------------------

To install a built version of the OpenShift SDK from the repository, just use:

    sudo yum install openshift-sdk

To install everything from the source tree, we use a tool called Tito (https://github.com/dgoodwin/tito):

    sudo yum install tito

Next, you can have tito build and install the RPM from HEAD with:

    sudo tito build --rpm -i --test

You could also have tito build and install off the latest stable tag with:

    sudo tito build --rpm -i

You can also have tito build the tarball, source RPM and other things:

    sudo tito build --tgz
    sudo tito build --srpm

Installing via Gem
------------------

To support multiple operating systems, the OpenShift SDK also supports Rubygem installations.  To install a built version of the OpenShift SDK Rubygem from the repository, just use:

    sudo gem install openshift-sdk

To build and install the gem from the source tree, use:

    gem build openshift-sdk.gemspec
    sudo gem install openshift-sdk*.gem

Local Env
---------

To run from a local checkout run:

    eval $( rake local_env | tail -n +1 )

Build Test Packages
-------------------

    mkdir /var/tmp/openshift-repo
    rake create_local_repo

    echo "[openshift]
    name=Openshift Repo
    baseurl=file:///var/tmp/openshift-repo
    enabled=1
    gpgcheck=0" > /etc/yum.repos.d/openshift.repo

Running Unit Tests
------------------

To run the unit tests for the project, use:

    rake test

Running Tests
-------------

To create a repo and run all tests:

    rake run_all_tests
