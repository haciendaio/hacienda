#!/bin/bash

umask 022
bundle install --deployment --without=test development --binstubs --path=vendor/bundle
