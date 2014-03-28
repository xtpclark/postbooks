name             'postbooks'
maintainer       'xTuple'
maintainer_email 'cloudops@xtuple.com'
license          'All rights reserved'
description      'Installs/Configures postbooks'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "sysctl"
depends "database"
depends "node"
