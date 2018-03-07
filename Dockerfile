FROM ruby

WORKDIR /usr/local/app

COPY Gemfile ./
RUN bundle

COPY . .

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0"]
