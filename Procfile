web: bundle exec puma -C config/puma.rb
worker: /usr/bin/env LIBRATO_AUTORUN=1 bundle exec sidekiq -c 5
release: rake db:migrate
