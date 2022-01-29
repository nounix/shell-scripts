#!/bin/bash

echo -n "Continue (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    exit 0
else
    exit 1
fi