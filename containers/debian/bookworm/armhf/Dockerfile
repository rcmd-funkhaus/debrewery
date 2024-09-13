FROM --platform=linux/arm/v7 debian:bookworm-slim

RUN apt-get -y update && apt-get -y install build-essential devscripts curl dh-make locales ruby-ronn && apt-get -y clean
RUN echo "en_US.UTF-8" >> /etc/locale.gen
RUN locale-gen

CMD /bin/true
