module.exports = {
  "**/*.{rb,rake,ru}": "bundle exec rubocop -a --force-exclusion",
  "{Gemfile,Rakefile}": "bundle exec rubocop -a --force-exclusion",
  "Gemfile.lock": () => "bundle exec bundler-audit check"
};
