#!/bin/bash

# Read the file line by line
while IFS='=' read -r key value; do
# Store each key-value pair as a variable
declare "$key=$value"
done < semver

echo "current api version: $version+$build"

increment_version() {
local increment_type=$1

IFS='.-' read -r -a version_parts <<< "$version"
major=${version_parts[0]}
minor=${version_parts[1]}
patch=${version_parts[2]}

case $increment_type in
major)
major=$((major + 1))
minor=0
patch=0
;;
minor)
minor=$((minor + 1))
patch=0
;;
patch)
patch=$((patch + 1))
;;
*)
echo "Unknown increment type: $increment_type"
exit 1
;;
esac

echo "$major.$minor.$patch"
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
echo "Usage: $0 <increment_type>"
exit 1
fi

increment_type=$1

new_version=$(increment_version $increment_type)
new_build=$((build += 1))

string_ver="$new_version+$build"
echo $string_ver

current_version="$new_version"

echo "building idiyanale-fe with version: $current_version"
docker build -t idiyanale-fe:$current_version . || {
echo "building image failed"
exit 1
}

echo "stopping idiyanale-fe"
docker stop idiyanale-fe || {
echo "stopping container failed"
exit 1
}

echo "removing idiyanale-fe"
docker rm idiyanale-fe || {
echo "removing container failed"
exit 1
}

echo "starting idiyanale-fe-$current_version"
docker run -it -d -p 65068:80 --restart unless-stopped --name idiyanale-fe idiyanale-fe:$current_version || {
echo "starting container failed"
exit 1
}

echo "version=$new_version
build=$new_build" > semver

echo "success"
