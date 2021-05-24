cp -R sqlsrv_drupalci drupal-project/sites/all/modules/sqlsrv
cp -R sqlsrv_drupalci/sqlsrv drupal-project/includes/database/sqlsrv
cp DrupalCI/src/settings.php drupal-project/sites/default/
mkdir -p drupal-project/sites/default/files/tmp
