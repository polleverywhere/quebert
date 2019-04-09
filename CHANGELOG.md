## 3.3.0

* Remove job argument log output. Job authors are expected to use logs if they find them necessary for their job execution. However, the default behavior has changed to no longer support this by default.
* Remove support for EOS/EOL ruby versions beyond 2.4.

## 3.2.1

* Fix bug with low priority constant value

## 3.2.0

* Add support for Beanstalk event hooks (#22)

## 3.1.0

* Add support for Ruby 2.4.1

## 3.0.0

* Add support for multiple tubes
* Allow params like ttr to be changed per job
