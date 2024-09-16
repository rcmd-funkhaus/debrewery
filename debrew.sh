#!/usr/bin/env bash

export WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NL='%0D%0A'

dump_output() {
   echo -e "\e[0;31mTailing the last 500 lines of output:\e[0m"
   tail -500 $BUILD_OUTPUT
}

function die() {
    STATUS=$1
    NAME=$2
    DISTRO=$3
    ARCHITECTURE=$4
    TASK=$5

    case $STATUS in
      'success' )
        echo "✅ SUCCESS${NL}Job number: ${TRAVIS_JOB_NUMBER}${NL}Package: ${NAME} ${NL}Distro: ${DISTRO}-${ARCHITECTURE} ${NL}Logs: https://travis-ci.org/${TRAVIS_REPO_SLUG}/jobs/${TRAVIS_JOB_ID}"
        ;;
      'failure' )
        dump_output
        echo "❌ FAILURE${NL}Job number: ${TRAVIS_JOB_NUMBER}${NL}Package: ${NAME} ${NL}Distro: ${DISTRO}-${ARCHITECTURE} ${NL}Logs: https://travis-ci.org/${TRAVIS_REPO_SLUG}/jobs/${TRAVIS_JOB_ID} ${NL}Failed task: ${TASK}"
        exit 1
        ;;
    esac
}

#-----------------


echo -e "\e[0;32mSetting up variables...\e[0m"

DEBREW_SUPPORTED_DISTRIBUTIONS="bookworm"
DEBREW_SUPPORTED_ARCHITECTURES="amd64
armhf
arm64"

DEBREW_IMAGE_SOURCE="repo.rcmd.space"
DEBREW_CWD=`pwd`
DEBREW_WORKDIR="/data"
DEBREW_REPO_OWNER=`echo $DEBREW_CWD | cut -f 5 -d '/'`
DEBREW_SOURCE_NAME=`dpkg-parsechangelog | grep Source | cut -f 2 -d ' '`
DEBREW_REVISION_PREFIX=`dpkg-parsechangelog | grep Version | cut -f 2 -d ' '`
DEBREW_VERSION_PREFIX=`echo $DEBREW_REVISION_PREFIX | cut -f 1 -d '-'`

PRODUCTION_FLAVOURS=`grep X-Debrew-Production-Flavours ./debian/control | cut -f 2- -d ' ' | jq -r '.[]'`
PRODUCTION_ARCHITECTURES=`grep X-Debrew-Production-Architectures ./debian/control | cut -f 2- -d ' ' | jq -r '.[]'`
TESTING_FLAVOURS=`grep X-Debrew-Testing-Flavours ./debian/control | cut -f 2- -d ' ' | jq -r '.[]'`
TESTING_ARCHITECTURES=`grep X-Debrew-Testing-Architectures ./debian/control | cut -f 2- -d ' ' | jq -r '.[]'`
PACKAGE_NAMES=`grep "Package: " ./debian/control | awk '{print $2}'`
DEBREW_MAINTAINER_LOGIN=`grep X-Debrew-Maintainer-Login ./debian/control | cut -f 2- -d ' '`

stable_hash=`git rev-list stable | head -n 1`
current_hash=`git rev-parse HEAD`
changelog_modified=`git show --name-only HEAD | grep -c 'debian/changelog'`

echo "Current CI tag is: ${DRONE_COMMIT_ID}"

if [[ $stable_hash == $current_hash ]]; then
    if [[ $DRONE_TAG == 'stable' ]]; then
        if [[ $PRODUCTION_FLAVOURS == 'any' ]]; then
            DEBREW_DISTRIBUTIONS=$DEBREW_SUPPORTED_DISTRIBUTIONS
        else
            DEBREW_DISTRIBUTIONS=$PRODUCTION_FLAVOURS
        fi
        if [[ $PRODUCTION_ARCHITECTURES == 'any' ]]; then
            DEBREW_ARCHITECTURES=$DEBREW_SUPPORTED_ARCHITECTURES
        else
            DEBREW_ARCHITECTURES=$PRODUCTION_ARCHITECTURES
        fi
        DEBREW_ENVIRONMENT='stable'
    else
        echo -e "\e[0;32mThis branch is not "stable", exiting gracefully.\e[0m"
        exit 0
    fi
else
    DEBREW_DISTRIBUTIONS=$(lsb_release -cs 2>/dev/null)
    DEBREW_ARCHITECTURES=$(dpkg --print-architecture)
    DEBREW_ENVIRONMENT='testing'
fi

for DISTRO in $DEBREW_DISTRIBUTIONS; do
    for ARCH in $DEBREW_ARCHITECTURES; do
        echo -e "\e[0;32mAssembling Dockerfile...\e[0m"
        echo -e "\e[0;32mDistribution: "$DISTRO"-"$ARCH"\e[0m"
        cat >Dockerfile <<EOF
FROM $DEBREW_IMAGE_SOURCE/debrewery-$DISTRO:$ARCH
RUN mkdir $DEBREW_WORKDIR
WORKDIR $DEBREW_WORKDIR
COPY . .
ENV DEBFULLNAME "Tiredsysadmin Repo"
ENV DEBEMAIL repo@tiredsysadmin.cc
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
EOF

        test -z $SECRET1 || echo "ENV SECRET1=$SECRET1" >> Dockerfile
        test -z $SECRET2 || echo "ENV SECRET2=$SECRET2" >> Dockerfile
        test -z $SECRET3 || echo "ENV SECRET3=$SECRET3" >> Dockerfile
        cat >> Dockerfile <<EOF
RUN apt-get -y update
RUN mk-build-deps --install --remove --tool 'apt-get --no-install-recommends --yes' debian/control
RUN dch --preserve --newversion $DEBREW_REVISION_PREFIX"+"$DISTRO ""
RUN dch --preserve -D $DISTRO --force-distribution ""
RUN dh_make --createorig -s -y -p $DEBREW_SOURCE_NAME"_"$DEBREW_VERSION_PREFIX || true
RUN debuild -e SECRET1 -e SECRET2 -e SECRET3 --no-tgz-check -us -uc
RUN cp ../*.deb /ext-build/ && ls -l /ext-build/
CMD /bin/true
EOF
        echo -e "\e[0;32mBuilding Docker container...\e[0m"
        mkdir ext-build
        podman build --tag="debrew/"$DEBREW_SOURCE_NAME"_"$DISTRO -v ${PWD}/ext-build:/ext-build .
        rm -f Dockerfile
        cd ./ext-build/ && ls -l
        echo -e "\e[0;32mPushing build artifacts to the repo...\e[0m"
        for NAME in $PACKAGE_NAMES; do
            PACKAGE_FULLNAME="${NAME}_${DEBREW_REVISION_PREFIX}+${DISTRO}_${ARCH}.deb"
            mv ${PACKAGE_FULLNAME} /opt/debian/incoming
            echo "Built package ${PACKAGE_FULLNAME}"
        done
        cd $DEBREW_CWD
        echo -e "\e[0;32mRemoving Docker container...\e[0m"
        rm -fr ./ext-build
        podman rmi -f localhost/debrew/${DEBREW_SOURCE_NAME}_${DISTRO}
    done
done
