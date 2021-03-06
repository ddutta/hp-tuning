#!/bin/bash

# Copyright 2018 The Kubeflow Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This shell script is used to build an image from our argo workflow

set -o errexit
set -o nounset
set -o pipefail

export PATH=${GOPATH}/bin:/usr/local/go/bin:${PATH}
REGISTRY="${GCP_REGISTRY}"
PROJECT="${GCP_PROJECT}"
GO_DIR=${GOPATH}/src/github.com/${REPO_OWNER}/${REPO_NAME}
VERSION=$(git describe --tags --always --dirty)

echo "Activating service-account"
gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
echo "Create symlink to GOPATH"
mkdir -p ${GOPATH}/src/github.com/${REPO_OWNER}
ln -s ${PWD} ${GO_DIR}
cd ${GO_DIR}
echo "Build operator binary"
mkdir bin
go build -o bin/katib-core github.com/kubeflow/hp-tuning/manager
go build -o bin/dlkmanager github.com/kubeflow/hp-tuning//dlk/dlkmanager
go build -o bin/katib-suggestion-grid github.com/kubeflow/hp-tuning/suggestion/grid
go build -o bin/katib-suggestion-hyperband github.com/kubeflow/hp-tuning/suggestion/hyperband
go build -o bin/katib-suggestion-random github.com/kubeflow/hp-tuning/suggestion/random
go build -o bin/katib github.com/kubeflow/hp-tuning/cli
#echo "building container in gcloud"
#gcloud version
# gcloud components update -q
cp manager/Dockerfile .
gcloud container builds submit . --tag=${REGISTRY}/${REPO_NAME}/vizier-core:${VERSION} --project=${PROJECT}
cp suggestion/random/Dockerfile .
gcloud container builds submit . --tag=${REGISTRY}/${REPO_NAME}/suggestion-random:${VERSION} --project=${PROJECT}
cp suggestion/grid/Dockerfile .
gcloud container builds submit . --tag=${REGISTRY}/${REPO_NAME}/suggestion-grid:${VERSION} --project=${PROJECT}
cp suggestion/hyperband/Dockerfile .
gcloud container builds submit . --tag=${REGISTRY}/${REPO_NAME}/suggestion-hyperband:${VERSION} --project=${PROJECT}
cp dlk/Dockerfile .
gcloud container builds submit . --tag=${REGISTRY}/${REPO_NAME}/dlk-manager:${VERSION} --project=${PROJECT}
cp manager/modeldb//Dockerfile .
gcloud container builds submit . --tag=${REGISTRY}/${REPO_NAME}/katib-frontend:${VERSION} --project=${PROJECT}
