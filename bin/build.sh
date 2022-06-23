#!/bin/sh

info () { echo -e "\033[33m$1\033[0m"; }
success () { echo -e "\033[32m$1\033[0m"; }
error () { echo -e "\033[31m$1\033[0m"; exit 1; }

IMAGE_NAMESPACE=${CI_IMAGE_NAMESPACE:-bdachina}
DOCKERFILE_SHAS_PATH="$CI_PROJECT_DIR/.dockerfile_shas"

DOCKERFILE_SHAS=`[ -f $DOCKERFILE_SHAS_PATH ] && cat $DOCKERFILE_SHAS_PATH`
echo > $DOCKERFILE_SHAS_PATH

for dockerfile_path in $(find * -type f -name Dockerfile); do
  image_path=$(dirname $dockerfile_path)
  image_tag=$IMAGE_NAMESPACE/${image_path//\//-}
  image_tag=${image_tag/-@/:}

  dockerfile_sha=`sha1sum $dockerfile_path`
  dockerfile_sha=${dockerfile_sha// /}

  if [ "$DOCKERFILE_SHAS" ]; then
    info "Start to check sha of $dockerfile_path"
    echo $DOCKERFILE_SHAS | grep "$dockerfile_sha"
    if [ $? -eq 0 ]; then
      info "$dockerfile_path is not changed"
      echo $dockerfile_sha >> $DOCKERFILE_SHAS_PATH
      continue
    fi
    success "Finish checking sha of $dockerfile_path"
  fi

  info "Start to pull $image_tag"
  docker pull $image_tag || info "No image found"
  success "Finish pulling $image_tag"

  info "Start to build $image_tag"
  docker build --cache-from $image_tag -t $image_tag $image_path || docker build -t $image_tag $image_path # Use cache for building if possible
  [ $? -ne 0 ] && error "It is failed to build $image_tag"
  success "Finish building $image_tag"

  info "Start to push $image_tag"
  docker push $image_tag
  [ $? -ne 0 ] && error "It is failed to push $image_tag"
  success "Finish pushing $image_tag"

  info "Start to save sha of $dockerfile_path"
  echo $dockerfile_sha >> $DOCKERFILE_SHAS_PATH
  success "Finish saving sha of $dockerfile_path"

  success "Build $image_tag successfully"
done