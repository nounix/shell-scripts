#!/bin/bash

CMD=''

[ "$1" = 'k' ] && shift && CMD="'/var/jenkins_home/bin/kubectl', '--insecure-skip-tls-verify', "

for arg in "$@"; do
    CMD="$CMD'$arg', "
done

SCRIPT=$(cat <<EOF
def cmd = [${CMD}]

cmd.execute().with{
    def output = new StringWriter()
    def error = new StringWriter()
    it.waitForProcessOutput(output, error)
    println "\n### JENKINS RESPONSE START ###"
    println "\$output"
    println "error=\$error"
    println "code=\${it.exitValue()}"
    println "\n### JENKINS RESPONSE END ###"
}
EOF
)

curl -s 'https://ci3.predic8.de/script' \
      -H 'Connection: keep-alive' \
      -H 'Cache-Control: max-age=0' \
      -H 'Origin: https://ci3.predic8.de' \
      -H 'Upgrade-Insecure-Requests: 1' \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36' \
      -H 'Sec-Fetch-Dest: document' \
      -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
      -H 'Sec-Fetch-Site: same-origin' \
      -H 'Sec-Fetch-Mode: navigate' \
      -H 'Sec-Fetch-User: ?1' \
      -H 'Referer: https://ci3.predic8.de/script' \
      -H 'Accept-Language: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7' \
      -H 'Cookie: screenResolution=1920x1080; JSESSIONID.523d166b=node0qzx4ww7f0cn37yiw0hz7gkef63.node0; JSESSIONID.32e2f010=node012u3cie685kqh1bij8rtubpo6o27.node0; jenkins-timestamper-offset=-7200000; ACEGI_SECURITY_HASHED_REMEMBER_ME_COOKIE=bWFydGlubToxNTg4MDU5MzEzMzMwOmNjOWQ1Yzk1MGNlMjdlNzA4NzYwY2E3ZTE5MDUzN2I0ZTQyYmZjNmYyMTA1N2E3MTc4ODU2ZGViMjcwZjgwMWQ=; JSESSIONID.ed945acb=node06p0zzs5fhnokvpxnsubhr37n62.node0' \
      --data-urlencode "script=$SCRIPT" \
      --data-urlencode 'Jenkins-Crumb=158fc2fcd0070b38681fd55e524c497a62c6d3a890eb71d65cc1050a6ed06eea' \
      --data-urlencode 'Submit=Ausführen' \
      --compressed \
      | sed -n -e '/^### JENKINS RESPONSE START ###/,/^### JENKINS RESPONSE END ###/ p'