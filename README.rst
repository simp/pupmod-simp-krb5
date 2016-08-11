|License| |Build Status| |SIMP compatibility|

Krb5 Puppet Module
==================

Table of Contents
-----------------

.. contents::
  :depth: 3

Overview
--------

Puppet management of the MIT Kerberos stack

This is a SIMP module
---------------------

This module is a component of the `System Integrity Management Platform`_, a
compliance-oriented systems management framework built on `Puppet`_.

If you find any issues, they can be submitted to our `JIRA`_.

Please read our `Contribution Guide`_ and visit our `developer wiki`_

This module is designed for use within a larger SIMP ecosystem, but many of its
functions can be used independently.

Setup
-----

What krb5 affects
^^^^^^^^^^^^^^^^^

The module, by default, sets up a fully functional KDC in your environment and
generates keytabs for one admin user, and all of your hosts that it can
discover via the SIMP ``keydist`` directory.

--------------------

  **NOTE**

  ``keydist`` discovery only works if the KDC is on the same system as your
  Puppet Server!

--------------------

Setup Requirements
^^^^^^^^^^^^^^^^^^

To use this module, simply install it into your environment's modulepath.

If you wish to have your keytabs available for automatic distribution via
puppet, you will need to create a ``krb5_files`` module that the ``puppet``
user can write to.

It is recommended that you make this a location that is separated from your
regular modules so that your code synchronization engine does not remove the
files and so that this sensitive information is not placed into revision
control.

The simplest method for doing this is to create an ``environment.conf`` file in
your environment that has something like the following:

.. code:: shell

   modulepath = modules:/var/simp/environments/<my_environment>/site_files:$basemodulepath

You will then need to create the target keytabs directory in that space so that
the puppet type knows that it should write the keytabs.

--------------------

  **WARNING**

  The ``simp`` directory in the example below should be used unless you
  explicitly set ``krb5::kdc::auto_keytabs::output_dir``.

--------------------

.. code:: shell

   mkdir -p /var/simp/environments/<my_environment>/site_files/krb5_files/files/keytabs
   chgrp -R puppet /var/simp
   chmod -R g+rX /var/simp
   chmod g+w /var/simp/environments/<my_environment>/site_files/krb5_files/files/keytabs

If you have SELinux enabled, don't forget to set your contexts appropriately!

.. code:: shell

   chcon -R -t puppet_var_lib_t /var/simp

Beginning with krb5
^^^^^^^^^^^^^^^^^^^

The following sections give a brief guide on how to get started, for more
information, please see the official `Red Hat documentation`_.

--------------------

  **NOTE**

  You can skip this section if you're using the default settings. These will
  complete the following for you with randomly generated passwords for all
  keytabs and the master password.

--------------------

Usage
-----

Automatically manage the KDC and keytabs on clients
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The examples in this section provides the hiera configuration needed to
automatically set up the KDC along with automated keytab distribution.

Set the following to be applied to all nodes that require Kerberos connectivity

.. code:: yaml

   classes:
     - 'krb5::keytab'

   simp_krb5: true

On your puppet server, set the following

.. code:: yaml

   classes:
     - 'krb5::kdc'

Keytab Propagation
^^^^^^^^^^^^^^^^^^

When puppet runs on the server, it will generate a set of keytabs, one per
known host. By default, the keytabs will be placed in
``/var/kerberos/krb5kdc/generated_keytabs/``. If the setup instructions were
followed for the puppet server, then the keytabs will be placed in the
created directory.

During subsequent client execution, each puppet client will have all generated
keytabs copied to their system in ``/etc/krb5_keytabs``. The default keytab,
``krb5.keytab``, will be copied to ``/etc/krb5.keytab`` and act as the system
default.

While it is unlikely that you will have more than one keytab, the facility has
been created to support that structure should you require it in the future for
different applications.

--------------------

  **NOTE**

  Should you opt out of combining your puppet server and KDC, you will need to
  copy the generated keytabs from your KDC to the puppet server and into a
  ``keytabs`` distribution space as specified in `Setup Requirements`. Be sure
  to properly set your permissions after copy!

--------------------

Manual Configuration and Expansion
----------------------------------

If you opt out of the automated process above, you can use the following to
generate keytabs for your principals and distribute them in a manner of your
choice.

Creating Admin Principals
^^^^^^^^^^^^^^^^^^^^^^^^^

ACL Configuration
"""""""""""""""""

The following Puppet code snippet will create an ACL for your admin user that
is **probably** appropriate for your organization.

.. code:: ruby

   krb5_acl{ "${::domain}_admin":
     principal       => "*/admin@${::domain}",
     operation_mask  => '*'
   }

Create Your Admin Principal
"""""""""""""""""""""""""""

Your first principal will be an admin principal and will be allowed to manage
the environment since it is in the `admin` group. This **must** be created on
the KDC system.

Run the following command, as root, to create your principal:

.. code:: bash

   # /usr/sbin/kadmin.local -r YOUR.DOMAIN -q "addprinc <username>/admin"

You can now do everything remotely using this principal. Load it using

.. code:: bash

   $ /usr/bin/kinit <username>/admin

Creating Host Principals
^^^^^^^^^^^^^^^^^^^^^^^^

Before you can really do anything with your hosts, you need to ensure that the
host itself has a keytab.

It is highly recommended that you use the instructions in `Setup Requirements`
to provide a protected space for your keytabs to be distributed.

On the KDC, generate a principal for each host in your environment using the
following:

.. code:: bash

   # /usr/sbin/kadmin.local -r YOUR.DOMAIN -q 'addprinc -randkey host/<fqdn>'

Create Your Keytabs
"""""""""""""""""""

Then, create a separate keytab file for each of your created hosts using the
following command:

.. code:: bash

   # /usr/sbin/kadmin.local -r YOUR.DOMAIN -q 'ktadd -k <fqdn>.keytab host/<fqdn>'


Once this is complete, the keys will be propagated across your environment per
`Keytab Propagation`.

Integration with NFS
^^^^^^^^^^^^^^^^^^^^

Please see our `NFS module documentation`_ or our `online documentation`_ for
information on how to integrate KRB5 with NFS.

Limitations
-----------

SIMP Puppet modules are generally intended to be used on a Red Hat Enterprise
Linux-compatible distribution.

Development
-----------

Please see the `SIMP Contribution Guidelines`_.

Acceptance tests
^^^^^^^^^^^^^^^^

To run the system tests, you need `Vagrant`_ installed.

You can then run the following to execute the acceptance tests:

.. code:: shell

   bundle exec rake beaker:suites

Some environment variables may be useful:

.. code:: shell

   BEAKER_debug=true
   BEAKER_provision=no
   BEAKER_destroy=no
   BEAKER_use_fixtures_dir_for_modules=yes

*  ``BEAKER_debug``: show the commands being run on the STU and their output.
*  ``BEAKER_destroy=no``: prevent the machine destruction after the tests
   finish so you can inspect the state.
*  ``BEAKER_provision=no``: prevent the machine from being recreated.  This can
   save a lot of time while you're writing the tests.
*  ``BEAKER_use_fixtures_dir_for_modules=yes``: cause all module dependencies
   to be loaded from the ``spec/fixtures/modules`` directory, based on the
   contents of ``.fixtures.yml``. The contents of this directory are usually
   populated by ``bundle exec rake spec_prep``. This can be used to run
   acceptance tests to run on isolated networks.

.. |License| image:: http://img.shields.io/:license-apache-blue.svg
   :target: http://www.apache.org/licenses/LICENSE-2.0.html
.. |Build Status| image:: https://travis-ci.org/simp/pupmod-simp-krb5.svg
   :target: https://travis-ci.org/simp/pupmod-simp-krb5
.. |SIMP compatibility| image:: https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg
   :target: https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg

.. _Contribution Guide: https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP
.. _JIRA:  https://simp-project.atlassian.net
.. _NFS module documentation: https://github.com/simp/pupmod-simp-nfs
.. _Puppet: https://puppet.com
.. _Red Hat documentation: https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Managing_Smart_Cards/Configuring_a_Kerberos_5_Server.html
.. _SIMP Contribution Guidelines: https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP
.. _System Integrity Management Platform: https://github.com/NationalSecurityAgency/SIMP
.. _Vagrant: https://www.vagrantup.com
.. _developer wiki: https://simp-project.atlassian.net/wiki/display/SD/SIMP+Development+Home
.. _online documentation: http://simp.readthedocs.io/en/master/user_guide/HOWTO/NFS.html
