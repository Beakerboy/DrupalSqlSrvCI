# Download SQL Server, postfix and apache
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-2019.list)"
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/16.04/prod.list)"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-get update -qq
sudo apt-get install -y -qq postfix apache2 libapache2-mod-fastcgi
sudo ACCEPT_EULA=Y apt-get install -y -qq mssql-server mssql-tools unixodbc-dev

# Remove Xdebug for speed
phpenv config-rm xdebug.ini

# Update pecl
pecl channel-update pecl.php.net

# Install SQL Server
export MSSQL_SA_PASSWORD=Password12!
export ACCEPT_EULA=Y
export MSSQL_PID=Evaluation
export SIMPLETEST_BASE_URL=http://127.0.0.1
sudo /opt/mssql/bin/mssql-conf setup
sleep 15
# add binary to path.
export PATH="/opt/mssql-tools/bin:$PATH"
sqlcmd -P Password12! -S localhost -U SA -Q "CREATE DATABASE mydrupalsite COLLATE LATIN1_GENERAL_100_CI_AS_SC_UTF8"

# Install the pdo_sqlsrv extension
sudo ACCEPT_EULA=Y apt-get -y install msodbcsql17 unixodbc-dev gcc g++ make autoconf libc-dev pkg-config
case $TRAVIS_PHP_VERSION in
  7.0)
    pecl install sqlsrv-5.3.0 pdo_sqlsrv-5.3.0
  ;;
  7.1 | 7.2)
    pecl install sqlsrv-5.6.1 pdo_sqlsrv-5.6.1
  ;;
  *)
    pecl install sqlsrv pdo_sqlsrv
  ;;
esac

# Install REGEX CLR
wget https://github.com/Beakerboy/drupal-sqlsrv-regex/releases/download/1.0/RegEx.dll
sudo mv RegEx.dll /var/opt/mssql/data/
sqlcmd -P Password12! -S localhost -U SA -d mydrupalsite -Q "EXEC sp_configure 'show advanced options', 1; RECONFIGURE; EXEC sp_configure 'clr strict security', 0; RECONFIGURE; EXEC sp_configure 'clr enable', 1; RECONFIGURE"
sqlcmd -P Password12! -S localhost -U SA -d mydrupalsite -Q "CREATE ASSEMBLY Regex from '/var/opt/mssql/data/RegEx.dll' WITH PERMISSION_SET = SAFE"
sqlcmd -P Password12! -S localhost -U SA -d mydrupalsite -Q "CREATE FUNCTION dbo.REGEXP(@pattern NVARCHAR(100), @matchString NVARCHAR(100)) RETURNS bit EXTERNAL NAME Regex.RegExCompiled.RegExCompiledMatch"

# Download Drupal components
export COMPOSER_MEMORY_LIMIT=-1
git clone https://git.drupalcode.org/project/drupal.git -b 7.x drupal-project
git clone https://git.drupalcode.org/project/sqlsrv.git -b 7.x-2.x sqlsrv_drupalci
cd drupal-project
composer require drush/drush:8.4.8

# if drupal version is specified, switch to the tagged branch.
if ![-z $DRUPAL_VERSION] or [$DRUPAL_VERSION != "7.x"]
then
  git checkout tags/$DRUPAL_VERSION
fi
cd ..

bash DrupalCI/src/travis/drupal7.x.sh
