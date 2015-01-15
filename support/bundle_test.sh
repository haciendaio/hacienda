#!/bin/bash

umask 022
bundle install --deployment --binstubs --without=production --path=vendor/test
