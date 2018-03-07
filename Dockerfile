FROM ruby

WORKDIR /usr/local/app

COPY Gemfile Gemfile.lock ./
RUN bundle

COPY . .

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0"]
