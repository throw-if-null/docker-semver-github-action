#!/bin/sh
set -e

function main() {
  echo "" # see https://github.com/actions/toolkit/issues/168

  sanitize "${INPUT_NAME}" "name"
  sanitize "${INPUT_USERNAME}" "username"
  sanitize "${INPUT_PASSWORD}" "password"

  setInputRegistry

  if uses "${INPUT_WORKDIR}"; then
    changeWorkingDirectory
  fi

  echo ${INPUT_PASSWORD} | docker login -u ${INPUT_USERNAME} --password-stdin ${INPUT_REGISTRY}

  BUILDPARAMS=""
  CONTEXT="."

  if uses "${INPUT_DOCKERFILE}"; then
    useCustomDockerfile
  fi
  if uses "${INPUT_BUILDARGS}"; then
    addBuildArgs
  fi
  if uses "${INPUT_CONTEXT}"; then
    CONTEXT="${INPUT_CONTEXT}"
  fi

  DOCKER_LATEST="${INPUT_NAME}:latest"

  echo "::debug file=entrypoint.sh::Starting docker build $BUILDPARAMS -t ${DOCKER_LATEST} ${CONTEXT}"
  BUILD_RESULT="$(docker build $BUILDPARAMS -t ${DOCKER_LATEST} ${CONTEXT})"
  echo "::debug file=entrypoint.sh::Build result: ${BUILD_RESULT}"
  echo "::debug file=entrypoint.sh::Finished building ${DOCKER_LATEST}"

  CONTAINER_ID="$(docker create ${DOCKER_LATEST})"
  docker cp $CONTAINER_ID:VERSION ./version
  docker rm $CONTAINER_ID
  VERSION="$(cat version)"
  docker stop ${DOCKER_LATEST}
  docker rm ${DOCKER_LATEST}
  
  echo "::debug file=entrypoint.sh::Version: $VERSION"

  echo "::debug file=entrypoint.sh::Starting docker push ${DOCKER_LATEST}"
  docker push ${DOCKER_LATEST}
  echo "::debug file=entrypoint.sh::Finished pushing ${DOCKER_LATEST}"

  if [ -z "${INPUT_SEMVER}" ]; then
    INPUT_SEMVER="latest"
  fi;

  if [ "${INPUT_SEMVER}" = "latest" ]; then
	outputAndLogout

	exit 0;
  fi;

  DOCKERNAME="${INPUT_NAME}:${INPUT_SEMVER}"

  echo "::debug file=entrypoint.sh::Starting docker tag ${DOCKER_LATEST} ${DOCKERNAME}"
  docker tag ${DOCKER_LATEST} ${DOCKERNAME}
  echo "::debug file=entrypoint.sh::Finished tagging ${DOCKER_LATEST} ${DOCKERNAME}"

  echo "::debug file=entrypoint.sh::Starting docker push ${DOCKERNAME}"
  docker push ${DOCKERNAME}
  echo "::debug file=entrypoint.sh::Finished pushing ${DOCKERNAME}"

  MAJOR="$(echo ${INPUT_SEMVER} | cut -d'.' -f1)"
  MINOR="$(echo ${INPUT_SEMVER} | cut -d'.' -f2)"
  PATCH="$(echo ${INPUT_SEMVER} | cut -d'.' -f3)"

  echo "::debug file=entrypoint.sh::Starting docker tag ${DOCKER_LATEST} ${INPUT_NAME}:${MAJOR}"
  docker tag ${DOCKER_LATEST} ${INPUT_NAME}:${MAJOR}
  echo "::debug file=entrypoint.sh::Finished tagging ${DOCKER_LATEST} ${INPUT_NAME}:${MAJOR}"

  echo "::debug file=entrypoint.sh::Starting docker push ${INPUT_NAME}:${MAJOR}"
  docker push ${INPUT_NAME}:${MAJOR}
  echo "::debug file=entrypoint.sh::Finished pushing ${INPUT_NAME}:${MAJOR}"

  echo "::debug file=entrypoint.sh::Starting docker tag ${DOCKER_LATEST} ${INPUT_NAME}:${MAJOR}.${MINOR}"
  docker tag ${DOCKER_LATEST} ${INPUT_NAME}:${MAJOR}.${MINOR}
  echo "::debug file=entrypoint.sh::Finished tagging ${DOCKER_LATEST} ${INPUT_NAME}:${MAJOR}.${MINOR}"

  echo "::debug file=entrypoint.sh::Starting docker push ${INPUT_NAME}:${MAJOR}.${MINOR}"
  docker push ${INPUT_NAME}:${MAJOR}.${MINOR}
  echo "::debug file=entrypoint.sh::Finished pushing ${INPUT_NAME}:${MAJOR}.${MINOR}"

  outputAndLogout
}


function sanitize() {
  if [ -z "${1}" ]; then
    >&2 echo "Unable to find the ${2}. Did you set with.${2}?"
    exit 1
  fi
}

function setInputRegistry() {
  REGISTRY_NO_PROTOCOL=$(echo "${INPUT_REGISTRY}" | sed -e 's/^https:\/\///g')

  if uses "${INPUT_REGISTRY}" && ! isPartOfTheName "${REGISTRY_NO_PROTOCOL}"; then
    INPUT_NAME="${REGISTRY_NO_PROTOCOL}/${INPUT_NAME}"
  fi
}

function isPartOfTheName() {
  [ $(echo "${INPUT_NAME}" | sed -e "s/${1}//g") != "${INPUT_NAME}" ]
}

function changeWorkingDirectory() {
  cd "${INPUT_WORKDIR}"
}

function useCustomDockerfile() {
  BUILDPARAMS="$BUILDPARAMS -f ${INPUT_DOCKERFILE}"
}

function addBuildArgs() {
  for arg in $(echo "${INPUT_BUILDARGS}" | tr ',' '\n'); do
    BUILDPARAMS="$BUILDPARAMS --build-arg ${arg}"
    echo "::add-mask::${arg}"
  done
}

function uses() {
  [ ! -z "${1}" ]
}

function usesBoolean() {
  [ ! -z "${1}" ] && [ "${1}" = "true" ]
}

function outputAndLogout() {
  echo ::set-output name=tag::"${INPUT_SEMVER}"

  docker logout
}

main
