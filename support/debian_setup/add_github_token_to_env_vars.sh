#!/bin/sh

echo  "export GITHUB_OAUTH_TOKEN=$1" >> ~/.bashrc
export GITHUB_OAUTH_TOKEN=$1