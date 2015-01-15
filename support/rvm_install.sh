#!/usr/bin/env bash

curl -sSL https://get.rvm.io | bash -s stable --ruby
source ~/.rvm/scripts/rvm
command rvm reload
