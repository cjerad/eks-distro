#!/usr/bin/env bash
# Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ "$AWS_ROLE_ARN" == "" ]; then
    echo "Empty AWS_ROLE_ARN"
    exit 1
fi

if [ "$ARTIFACT_DEPLOYMENT_ROLE_ARN" == "" ]; then
    echo "Empty ARTIFACT_DEPLOYMENT_ROLE_ARN"
    exit 1
fi

BASE_DIRECTORY=$(git rev-parse --show-toplevel)
cd ${BASE_DIRECTORY}
RELEASE_ENVIRONMENT=${RELEASE_ENVIRONMENT:-development}

export RELEASE=$(cat ${BASE_DIRECTORY}/release/${RELEASE_BRANCH}/${RELEASE_ENVIRONMENT}/RELEASE)

if [ "${RELEASE}" == "0" ]
then
    echo "No production release zero"
    exit 0
fi

cat << EOF > awscliconfig
[default]
output=json
region=${AWS_REGION:-${AWS_DEFAULT_REGION:-us-west-2}}
role_arn=$AWS_ROLE_ARN
web_identity_token_file=/var/run/secrets/eks.amazonaws.com/serviceaccount/token

[profile release-account]
role_arn=$ARTIFACT_DEPLOYMENT_ROLE_ARN
region=${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}
source_profile=default
EOF
export AWS_CONFIG_FILE=$(pwd)/awscliconfig
export AWS_PROFILE=release-account
unset AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE

cp -r /$HOME/.docker ${BASE_DIRECTORY}
export DOCKER_CONFIG=${BASE_DIRECTORY}/.docker
${BASE_DIRECTORY}/development/ecr/ecr-command.sh install-ecr-public
${BASE_DIRECTORY}/development/ecr/ecr-command.sh login-ecr-public
make release ${*}
