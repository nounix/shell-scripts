#!/bin/bash

URL_DIST="https://services.gradle.org/distributions/"
URL_GRADLE="$(curl -s $URL_DIST | sed -n 's/.*\(gradle-[[:digit:]]*\.[[:digit:]]*\.*[[:digit:]]*-bin\.zip\).*/\1/p' | head -n1)"

mkdir -p /tmp/gradle-wrapper/combine ./gradle/wrapper

wget -qO /tmp/gradle-wrapper/gradle.zip "$URL_DIST$URL_GRADLE"
unzip -qq -d /tmp/gradle-wrapper/gradle /tmp/gradle-wrapper/gradle.zip

(cd /tmp/gradle-wrapper/combine; unzip -uo /tmp/gradle-wrapper/gradle/gradle-*/lib/gradle-wrapper-*.jar)
(cd /tmp/gradle-wrapper/combine; unzip -uo /tmp/gradle-wrapper/gradle/gradle-*/lib/gradle-cli-*.jar)
jar -cvf ./gradle/wrapper/gradle-wrapper.jar -C /tmp/gradle-wrapper/combine .

wget -qO ./gradlew "https://raw.githubusercontent.com/gradle/gradle/master/gradlew"
chmod +x ./gradlew

wget -qO ./gradle/wrapper/gradle-wrapper.properties "https://raw.githubusercontent.com/gradle/gradle/master/gradle/wrapper/gradle-wrapper.properties"
sed -i "s/distributionUrl=.*/distributionUrl=$(echo $URL_DIST | sed 's/\//\\\//g' | sed 's/:/\\\\:/')$URL_GRADLE/" ./gradle/wrapper/gradle-wrapper.properties
