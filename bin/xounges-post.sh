cd /home/davidg/gits/apartmentpricer
git pull xounges master; 
chown -R davidg:davidg /var/www-rails/apartmentpricer/; 
git archive master | tar -x -C /var/www-rails/apartmentpricer/; 
chown -R www-data:www-data /var/www-rails/apartmentpricer/; 
/etc/init.d/nginx restart
chown -R davidg:davidg /var/www-rails/apartmentpricer/; 

cd /var/www-rails/apartmentpricer/
/home/davidg/.rvm/wrappers/ruby-2.1.0/rake db:migrate RAILS_ENV=production; 
RAILS_ENV=production /home/davidg/.rvm/wrappers/ruby-2.1.0/bundle exec /home/davidg/.rvm/wrappers/ruby-2.1.0/rake assets:precompile; 
chown -R www-data:www-data /var/www-rails/apartmentpricer/; 
/etc/init.d/nginx restart
