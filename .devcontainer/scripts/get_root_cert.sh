echo -e "Scraping root certificate..."

openssl s_client -showcerts -connect julialang.org:443 </dev/null | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){a++}; out="cert"a".crt"; print >out}'

mv *.crt /usr/local/share/ca-certificates/


