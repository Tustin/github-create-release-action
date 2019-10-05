#!/bin/bash
################################################################################
# Descrição:
#   Script Github Actions to create a new release automatically
################################################################################

set -e
set -o pipefail

# ============================================
# Function to create a new release in Github API
# ============================================
request_create_release(){

	local json_body= '{
	  "tag_name": "@tag_name@",
	  "target_commitish": "@branch@",
	  "name": "@release_name@",
	  "body": "@description@",
	  "draft": true,
	  "prerelease": false
	}'

	json_body=$(echo "$json_body" | sed "s/@tag_name@/$git_tag/")
	json_body=$(echo "$json_body" | sed "s/@branch@/master/")
	json_body=$(echo "$json_body" | sed "s/@release_name@/Release $git_tag/")
	json_body=$(echo "$json_body" | sed "s/@description@/$DESCRIPTION/")

	curl --request POST \
	  --url https://api.github.com/repos/${GITHUB_REPOSITORY}/releases \
	  --header "Authorization: Bearer $GITHUB_TOKEN" \
	  --header 'Content-Type: application/json' \
	  --data "$json_body"
}

# ==================== MAIN ====================

# Ensure that the GITHUB_TOKEN secret is included
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

last_tag_number=$(git tag -l | sort -V | tail -n 1 | cut -c 2- | cut -d '.' -f1)

# if not exist env var $VERSION
# get tag by 'git tag' command
if [[ -z "$VERSION" ]]; then
	# If null, is the first release
	if [ $(git tag | wc -l) = "0" ];then
		git_tag="v1.0"
		request_create_release
	else
		new_tag=$(echo "$last_tag_number + 1" | bc)
		# git_tag="v${new_tag}.0"
		git_tag="v${new_tag}.0"
		request_create_release
	fi
# if env var $VERSION exist, use it
else
	echo "DEBUG: env VERSION = $VERSION"
	# if en var $VERSION don't start with 'v', add 'v' in
	# start of string
	if [ $(echo "$VERSION" | cut -c 1) != 'v' ];then
		VERSION="v$VERSION"
	fi

	# verify if $VERSION already exist in git tag list
	if git tag -l | grep -q "$VERSION";then
		echo "tag $VERSION already exist"
		exit 1
	fi

	first_number_version=$(echo $VERSION | cut -c 2)
	if [ $first_number_version -lt $last_tag_number ];then
		echo "the env var $VERSION is less than last tag: $last_tag_number"
		exit 1
	fi

	# if everything ok, the new version is env $VERSION
	git_tag="$VERSION"
	request_create_release
fi
