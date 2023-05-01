#!/bin/bash

figlet "Vuln-Check"
echo "by Shoumik Chandra"


# prompt the user to enter the target website URL
read -p "Enter the target website URL: " TARGET_URL

# check for Injection vulnerabilities
SQL_INJECTION=$(curl -s -d "username=admin&password=admin' OR 1=1 --" "$TARGET_URL/login" | grep -q -i "welcome back admin")
if [ $? -eq 0 ]; then
  echo "SQL Injection vulnerability found!"
fi

XSS_PAYLOAD="<script>alert(1)</script>"
REFLECTED_XSS=$(curl -s -X POST -d "$XSS_PAYLOAD" "$TARGET_URL/search?q=$XSS_PAYLOAD" | grep -q -i "$XSS_PAYLOAD")
if [ $? -eq 0 ]; then
  echo "Reflected XSS vulnerability found!"
fi

CSRF=$(curl -s -b "sessionid=123" -X POST -H "Referer: $TARGET_URL" -d "amount=100&to=attacker" "$TARGET_URL/transfer")
if echo "$CSRF" | grep -q "Successful transfer"; then
  echo "CSRF vulnerability found!"
fi

# check for Broken Authentication and Session Management vulnerabilities
SESSION_TOKEN=$(curl -s -c cookies.txt "$TARGET_URL/login" | grep "sessionid" | awk '{print $7}')
curl -s -b "sessionid=$SESSION_TOKEN" "$TARGET_URL/logout"
if ! curl -s -b "sessionid=$SESSION_TOKEN" "$TARGET_URL/dashboard" | grep -q "Welcome"; then
  echo "Broken Authentication vulnerability found!"
fi

# check for Security Misconfiguration vulnerabilities
curl -s -H "X-Forwarded-For: 127.0.0.1" "$TARGET_URL/admin" | grep -q -i "403 Forbidden"
if [ $? -eq 0 ]; then
  echo "Security Misconfiguration vulnerability found!"
fi

# check for Insecure Cryptographic Storage vulnerabilities
PASSWORD_HASH=$(curl -s "$TARGET_URL/user/1" | grep "Password" | awk '{print $3}')
if echo "$PASSWORD_HASH" | grep -q -i -e "md5" -e "sha1"; then
  echo "Insecure Cryptographic Storage vulnerability found!"
fi

# check for Insufficient Transport Layer Protection vulnerabilities
curl -s -k "$TARGET_URL/login" | grep -q -i "password" && echo "Insufficient Transport Layer Protection vulnerability found!"

# check for Insufficient Authorization vulnerabilities
SECRET_PAGE=$(curl -s -b "sessionid=123" "$TARGET_URL/secret")
if echo "$SECRET_PAGE" | grep -q -i "You are not authorized"; then
  echo "Insufficient Authorization vulnerability found!"
fi

# check for Unvalidated and Unsanitized Inputs vulnerabilities
echo "1" | curl -s -X POST -H "Content-Type: application/json" -d '{"amount": 100}' "$TARGET_URL/transfer" | grep -q -i "Error: Invalid input"
if [ $? -eq 0 ]; then
  echo "Unvalidated and Unsanitized Inputs vulnerability found!"
fi

# check for Components with Known Vulnerabilities vulnerabilities
if curl -s "$TARGET_URL/lib/jquery.js" | grep -q "known vulnerabilities"; then
  echo "Components with Known Vulnerabilities vulnerability found!"
fi

