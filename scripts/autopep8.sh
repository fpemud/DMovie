#!/bin/bash

FILES="$(find . -name '*.py' | tr '\n' ' ')"

autopep8 -ia --ignore=E501 ${FILES}
