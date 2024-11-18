FROM --platform=linux/arm64 debian:buster-slim

RUN apt-get -y update && apt-get -y install build-essential devscripts curl dh-make locales ruby-ronn && apt-get -y clean
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen

CMD /bin/true
