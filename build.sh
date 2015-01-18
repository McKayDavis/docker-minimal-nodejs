#!/bin/sh

# bail on error
set -e


ROOTDIR=$(pwd -P)
PROJECT=docker-minimal-nodejs
TMPDIR=/tmp/${PROJECT}

if [ ! -f Dockerfile.step1 ]; then
    echo "Script must be run from same directory as Dockerfile.step1"
    exit 1
fi


echo ROOTDIR=$ROOTDIR

# The latest node.js distribution is held here
BASE_URL=http://nodejs.org/dist/latest/

# Extract the name of the 64-bit linux distro from the directory listing
PACKAGE=$(curl ${BASE_URL} | egrep -o 'node-[^"]+-linux-x64.tar.gz' | uniq)

URL=${BASE_URL}/${PACKAGE}

echo
echo $PACKAGE is the latest version
echo Retreiving $URL...

rm -rf ${TMPDIR}
mkdir ${TMPDIR}
cd ${TMPDIR}

curl -O $URL

# Get the basename for the package
PACKAGE_NAME=$(basename ${PACKAGE} .tar.gz)

echo PACKAGE_NAME=${PACKAGE_NAME}

# String replace the token in the dockerfile
sed "s/PACKAGE_NAME/${PACKAGE_NAME}/g" ${ROOTDIR}/Dockerfile.step1 > Dockerfile

docker build -t ${PROJECT}-builder .

mkdir rootfs

docker run --rm ${PROJECT}-builder | tar xz -C rootfs

cp -f ${ROOTDIR}/Dockerfile.step2 Dockerfile

docker build -t ${PROJECT} .


cd $ROOTDIR
rm -rf ${TMPDIR}

echo "Docker image ${PROJECT} created"
echo "To get a node REPL, run:"
echo "docker run -ti ${PROJECT}"
