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
