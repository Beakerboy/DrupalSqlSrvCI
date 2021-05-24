sudo service postfix stop
smtp-sink -d "%d.%H.%M.%S" localhost:2500 1000 &
echo -e '#!/usr/bin/env bash\nexit 0' | sudo tee /usr/sbin/sendmail
echo 'sendmail_path = "/usr/sbin/sendmail -t -i "' | sudo tee "/home/travis/.phpenv/versions/`php -i | grep "PHP Version" | head -n 1 | grep -o -P '\d+\.\d+\.\d+.*'`/etc/conf.d/sendmail.ini"
cd drupal-project
vendor/bin/drush si standard -y --db-url=sqlsrv://sa:Password12!@localhost/mydrupalsite --clean-url=0 --account-name=admin --account-pass=drupal
vendor/bin/drush en -y simpletest
cd ..
