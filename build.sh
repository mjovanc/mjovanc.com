#!/bin/bash

# copy cname record temporary to preserve it
mkdir -p ~/preserved
cp docs/CNAME ~/preserved/CNAME

# build zola
zola build

# copy back the cname record for version control
cp ~/preserved/CNAME docs/CNAME