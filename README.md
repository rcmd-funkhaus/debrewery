# debrewery
Automated building of Debian packages using Travis CI

### Usage

```
sudo: required

services:
  - docker

script:
  - wget -O- https://raw.githubusercontent.com/it-the-drote/debrewery/master/debrew.sh | bash -
```

### Docker image requirements

Debian packages:
+ build-essential
+ devscripts
+ curl
+ dh-make
+ locales(DEBIAN)
+ `locale-gen en_US.UTF-8`(UBUNTU) 
+ ruby-ronn
