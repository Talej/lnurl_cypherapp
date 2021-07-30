#!/bin/sh

# Happy path:
#
# 1. Create a LNURL Withdraw
# 2. Get it and compare
# 3. User calls LNServiceWithdrawRequest with wrong k1 -> Error, wrong k1!
# 3. User calls LNServiceWithdrawRequest
# 4. User calls LNServiceWithdraw with wrong k1 -> Error, wrong k1!
# 4. User calls LNServiceWithdraw

# Expired 1:
#
# 1. Create a LNURL Withdraw with expiration=now
# 2. Get it and compare
# 3. User calls LNServiceWithdrawRequest -> Error, expired!

# Expired 2:
#
# 1. Create a LNURL Withdraw with expiration=now + 5 seconds
# 2. Get it and compare
# 3. User calls LNServiceWithdrawRequest
# 4. Sleep 5 seconds
# 5. User calls LNServiceWithdraw -> Error, expired!

# Deleted 1:
#
# 1. Create a LNURL Withdraw with expiration=now
# 2. Get it and compare
# 3. Delete it
# 4. Get it and compare
# 5. User calls LNServiceWithdrawRequest -> Error, deleted!

# Deleted 2:
#
# 1. Create a LNURL Withdraw with expiration=now + 5 seconds
# 2. Get it and compare
# 5. User calls LNServiceWithdrawRequest
# 3. Delete it
# 5. User calls LNServiceWithdraw -> Error, deleted!

. ./tests/colors.sh

trace() {
  if [ "${1}" -le "${TRACING}" ]; then
    local str="$(date -Is) $$ ${2}"
    echo -e "${str}" 1>&2
  fi
}

create_lnurl_withdraw() {
  trace 1 "\n[create_lnurl_withdraw] ${BCyan}Service creates LNURL Withdraw...${Color_Off}"

  local callbackurl=${1}

  local invoicenumber=$RANDOM
  trace 2 "[create_lnurl_withdraw] invoicenumber=${invoicenumber}"
  local amount=$((10000+${invoicenumber}))
  trace 2 "[create_lnurl_withdraw] amount=${amount}"
  local expiration_offset=${2:-0}
  local expiration=$(date -d @$(($(date -u +"%s")+${expiration_offset})) +"%Y-%m-%dT%H:%M:%SZ")
  trace 2 "[create_lnurl_withdraw] expiration=${expiration}"

  # Service creates LNURL Withdraw
  data='{"id":0,"method":"createLnurlWithdraw","params":{"amount":'${amount}',"description":"desc'${invoicenumber}'","expiration":"'${expiration}'","secretToken":"secret'${invoicenumber}'","webhookUrl":"'${callbackurl}'/lnurl/inv'${invoicenumber}'"}}'
  trace 2 "[create_lnurl_withdraw] data=${data}"
  trace 2 "[create_lnurl_withdraw] Calling createLnurlWithdraw..."
  local createLnurlWithdraw=$(curl -sd "${data}" -H "Content-Type: application/json" lnurl:8000/api)
  trace 2 "[create_lnurl_withdraw] createLnurlWithdraw=${createLnurlWithdraw}"

  # {"id":0,"result":{"amount":0.01,"description":"desc01","expiration":"2021-07-15T12:12:23.112Z","secretToken":"abc01","webhookUrl":"https://webhookUrl01","lnurl":"LNURL1DP68GUP69UHJUMMWD9HKUW3CXQHKCMN4WFKZ7AMFW35XGUNPWAFX2UT4V4EHG0MN84SKYCESXYH8P25K","withdrawnDetails":null,"withdrawnTimestamp":null,"active":1,"lnurlWithdrawId":1,"createdAt":"2021-07-15 19:42:06","updatedAt":"2021-07-15 19:42:06"}}
  local lnurl=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurl")
  trace 2 "[create_lnurl_withdraw] lnurl=${lnurl}"

  echo "${createLnurlWithdraw}"
}

get_lnurl_withdraw() {
  trace 1 "\n[get_lnurl_withdraw] ${BCyan}Get LNURL Withdraw...${Color_Off}"

  local lnurl_withdraw_id=${1}
  trace 2 "[get_lnurl_withdraw] lnurl_withdraw_id=${lnurl_withdraw_id}"

  # Service creates LNURL Withdraw
  data='{"id":0,"method":"getLnurlWithdraw","params":{"lnurlWithdrawId":'${lnurl_withdraw_id}'}}'
  trace 2 "[get_lnurl_withdraw] data=${data}"
  trace 2 "[get_lnurl_withdraw] Calling getLnurlWithdraw..."
  local getLnurlWithdraw=$(curl -sd "${data}" -H "Content-Type: application/json" lnurl:8000/api)
  trace 2 "[get_lnurl_withdraw] getLnurlWithdraw=${getLnurlWithdraw}"

  echo "${getLnurlWithdraw}"
}

delete_lnurl_withdraw() {
  trace 1 "\n[delete_lnurl_withdraw] ${BCyan}Delete LNURL Withdraw...${Color_Off}"

  local lnurl_withdraw_id=${1}
  trace 2 "[delete_lnurl_withdraw] lnurl_withdraw_id=${lnurl_withdraw_id}"

  # Service deletes LNURL Withdraw
  data='{"id":0,"method":"deleteLnurlWithdraw","params":{"lnurlWithdrawId":'${lnurl_withdraw_id}'}}'
  trace 2 "[delete_lnurl_withdraw] data=${data}"
  trace 2 "[delete_lnurl_withdraw] Calling deleteLnurlWithdraw..."
  local deleteLnurlWithdraw=$(curl -sd "${data}" -H "Content-Type: application/json" lnurl:8000/api)
  trace 2 "[delete_lnurl_withdraw] deleteLnurlWithdraw=${deleteLnurlWithdraw}"

  local active=$(echo "${deleteLnurlWithdraw}" | jq ".result.active")
  if [ "${active}" = "true" ]; then
    trace 2 "[delete_lnurl_withdraw] ${On_Red}${BBlack} NOT DELETED!                                                                          ${Color_Off}"
    return 1
  fi

  echo "${deleteLnurlWithdraw}"
}

decode_lnurl() {
  trace 1 "\n[decode_lnurl] ${BCyan}Decoding LNURL...${Color_Off}"

  local lnurl=${1}
  local lnServicePrefix=${2}

  local data='{"id":0,"method":"decodeBech32","params":{"s":"'${lnurl}'"}}'
  trace 2 "[decode_lnurl] data=${data}"
  local decodedLnurl=$(curl -sd "${data}" -H "Content-Type: application/json" lnurl:8000/api)
  trace 2 "[decode_lnurl] decodedLnurl=${decodedLnurl}"
  local urlSuffix=$(echo "${decodedLnurl}" | jq -r ".result" | sed 's|'${lnServicePrefix}'||g')
  trace 2 "[decode_lnurl] urlSuffix=${urlSuffix}"

  echo "${urlSuffix}"
}

call_lnservice_withdraw_request() {
  trace 1 "\n[call_lnservice_withdraw_request] ${BCyan}User calls LN Service LNURL Withdraw Request...${Color_Off}"

  local urlSuffix=${1}

  local withdrawRequestResponse=$(curl -s lnurl:8000${urlSuffix})
  trace 2 "[call_lnservice_withdraw_request] withdrawRequestResponse=${withdrawRequestResponse}"

  echo "${withdrawRequestResponse}"
}

create_bolt11() {
  trace 1 "\n[create_bolt11] ${BCyan}User creates bolt11 for the payment...${Color_Off}"

  local amount=${1}
  trace 2 "[create_bolt11] amount=${amount}"
  local desc=${2}
  trace 2 "[create_bolt11] desc=${desc}"

  local data='{"id":1,"jsonrpc": "2.0","method":"invoice","params":{"msatoshi":'${amount}',"label":"'${desc}'","description":"'${desc}'"}}'
  trace 2 "[create_bolt11] data=${data}"
  local invoice=$(curl -sd "${data}" -H 'X-Access:FoeDdQw5yl7pPfqdlGy3OEk/txGqyJjSbVtffhzs7kc=' -H "Content-Type: application/json" cyphernode_sparkwallet2:9737/rpc)
  trace 2 "[create_bolt11] invoice=${invoice}"

  echo "${invoice}"
}

get_invoice_status() {
  trace 1 "\n[get_invoice_status] ${BCyan}Let's make sure the invoice is unpaid first...${Color_Off}"

  local invoice=${1}
  trace 2 "[get_invoice_status] invoice=${invoice}"

  local payment_hash=$(echo "${invoice}" | jq -r ".payment_hash")
  trace 2 "[get_invoice_status] payment_hash=${payment_hash}"
  local data='{"id":1,"jsonrpc": "2.0","method":"listinvoices","params":{"payment_hash":"'${payment_hash}'"}}'
  trace 2 "[get_invoice_status] data=${data}"
  local invoices=$(curl -sd "${data}" -H 'X-Access:FoeDdQw5yl7pPfqdlGy3OEk/txGqyJjSbVtffhzs7kc=' -H "Content-Type: application/json" cyphernode_sparkwallet2:9737/rpc)
  trace 2 "[get_invoice_status] invoices=${invoices}"
  local status=$(echo "${invoices}" | jq -r ".invoices[0].status")
  trace 2 "[get_invoice_status] status=${status}"

  echo "${status}"
}

call_lnservice_withdraw() {
  trace 1 "\n[call_lnservice_withdraw] ${BCyan}User prepares call to LN Service LNURL Withdraw...${Color_Off}"

  local withdrawRequestResponse=${1}
  local lnServicePrefix=${2}
  local bolt11=${3}

  callback=$(echo "${withdrawRequestResponse}" | jq -r ".callback")
  trace 2 "[call_lnservice_withdraw] callback=${callback}"
  urlSuffix=$(echo "${callback}" | sed 's|'${lnServicePrefix}'||g')
  trace 2 "[call_lnservice_withdraw] urlSuffix=${urlSuffix}"
  k1=$(echo "${withdrawRequestResponse}" | jq -r ".k1")
  trace 2 "[call_lnservice_withdraw] k1=${k1}"

  trace 2 "\n[call_lnservice_withdraw] ${BCyan}User finally calls LN Service LNURL Withdraw...${Color_Off}"
  withdrawResponse=$(curl -s lnurl:8000${urlSuffix}?k1=${k1}\&pr=${bolt11})
  trace 2 "[call_lnservice_withdraw] withdrawResponse=${withdrawResponse}"

  echo "${withdrawResponse}"
}

happy_path() {
  # Happy path:
  #
  # 1. Create a LNURL Withdraw
  # 2. Get it and compare
  # 3. User calls LNServiceWithdrawRequest with wrong k1 -> Error, wrong k1!
  # 3. User calls LNServiceWithdrawRequest
  # 4. User calls LNServiceWithdraw with wrong k1 -> Error, wrong k1!
  # 4. User calls LNServiceWithdraw

  trace 1 "\n[happy_path] ${On_Yellow}${BBlack} Happy path!                                                                     ${Color_Off}"

  local callbackurl=${1}
  local lnServicePrefix=${2}

  # Service creates LNURL Withdraw
  local createLnurlWithdraw=$(create_lnurl_withdraw "${callbackurl}" 15)
  trace 2 "[happy_path] createLnurlWithdraw=${createLnurlWithdraw}"
  local lnurl=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurl")
  #trace 2 "lnurl=${lnurl}"

  local lnurl_withdraw_id=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurlWithdrawId")
  local get_lnurl_withdraw=$(get_lnurl_withdraw ${lnurl_withdraw_id})
  trace 2 "[happy_path] get_lnurl_withdraw=${get_lnurl_withdraw}"
  local equals=$(jq --argjson a "${createLnurlWithdraw}" --argjson b "${get_lnurl_withdraw}" -n '$a == $b')
  trace 2 "[happy_path] equals=${equals}"
  if [ "${equals}" = "true" ]; then
    trace 2 "[happy_path] EQUALS!"
  else
    trace 1 "[happy_path] ${On_Red}${BBlack} NOT EQUALS!                                                                          ${Color_Off}"
    return 1
  fi

  # Decode LNURL
  local urlSuffix=$(decode_lnurl "${lnurl}" "${lnServicePrefix}")
  trace 2 "[happy_path] urlSuffix=${urlSuffix}"

  # User calls LN Service LNURL Withdraw Request
  local withdrawRequestResponse=$(call_lnservice_withdraw_request "${urlSuffix}")
  trace 2 "[happy_path] withdrawRequestResponse=${withdrawRequestResponse}"

  # Create bolt11 for LN Service LNURL Withdraw
  local amount=$(echo "${createLnurlWithdraw}" | jq -r '.result.amount')
  local description=$(echo "${createLnurlWithdraw}" | jq -r '.result.description')
  local invoice=$(create_bolt11 "${amount}" "${description}")
  trace 2 "[happy_path] invoice=${invoice}"
  local bolt11=$(echo ${invoice} | jq -r ".bolt11")
  trace 2 "[happy_path] bolt11=${bolt11}"

  # We want to see that that invoice is unpaid first...
  local status=$(get_invoice_status "${invoice}")
  trace 2 "[happy_path] status=${status}"

  # User calls LN Service LNURL Withdraw
  local withdrawResponse=$(call_lnservice_withdraw "${withdrawRequestResponse}" "${lnServicePrefix}" "${bolt11}")
  trace 2 "[happy_path] withdrawResponse=${withdrawResponse}"

  trace 2 "[happy_path] Sleeping 5 seconds..."
  sleep 5

  # We want to see if payment received (invoice status paid)
  status=$(get_invoice_status "${invoice}")
  trace 2 "[happy_path] status=${status}"

  if [ "${status}" = "paid" ]; then
    trace 1 "\n[happy_path] ${On_IGreen}${BBlack} SUCCESS!                                                                       ${Color_Off}"
    date
    return 0
  else
    trace 1 "\n[happy_path] ${On_Red}${BBlack} FAILURE!                                                                         ${Color_Off}"
    date
    return 1
  fi
}

expired1() {
  # Expired 1:
  #
  # 1. Create a LNURL Withdraw with expiration=now
  # 2. Get it and compare
  # 3. User calls LNServiceWithdrawRequest -> Error, expired!

  trace 1 "\n[expired1] ${On_Yellow}${BBlack} Expired 1!                                                                        ${Color_Off}"

  local callbackurl=${1}
  local lnServicePrefix=${2}

  # Service creates LNURL Withdraw
  local createLnurlWithdraw=$(create_lnurl_withdraw "${callbackurl}" 0)
  trace 2 "[expired1] createLnurlWithdraw=${createLnurlWithdraw}"
  local lnurl=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurl")
  #trace 2 "lnurl=${lnurl}"

  local lnurl_withdraw_id=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurlWithdrawId")
  local get_lnurl_withdraw=$(get_lnurl_withdraw ${lnurl_withdraw_id})
  trace 2 "[expired1] get_lnurl_withdraw=${get_lnurl_withdraw}"
  local equals=$(jq --argjson a "${createLnurlWithdraw}" --argjson b "${get_lnurl_withdraw}" -n '$a == $b')
  trace 2 "[expired1] equals=${equals}"
  if [ "${equals}" = "true" ]; then
    trace 2 "[expired1] EQUALS!"
  else
    trace 1 "[expired1] ${On_Red}${BBlack} NOT EQUALS!                                                                          ${Color_Off}"
    return 1
  fi

  # Decode LNURL
  local urlSuffix=$(decode_lnurl "${lnurl}" "${lnServicePrefix}")
  trace 2 "[expired1] urlSuffix=${urlSuffix}"

  # User calls LN Service LNURL Withdraw Request
  local withdrawRequestResponse=$(call_lnservice_withdraw_request "${urlSuffix}")
  trace 2 "[expired1] withdrawRequestResponse=${withdrawRequestResponse}"

  echo "${withdrawRequestResponse}" | grep -qi "expired"
  if [ "$?" -ne "0" ]; then
    trace 1 "[expired1] ${On_Red}${BBlack} NOT EXPIRED!                                                                         ${Color_Off}"
    return 1
  else
    trace 1 "\n[expired1] ${On_IGreen}${BBlack} SUCCESS!                                                                       ${Color_Off}"
  fi
}

expired2() {
  # Expired 2:
  #
  # 1. Create a LNURL Withdraw with expiration=now + 5 seconds
  # 2. Get it and compare
  # 3. User calls LNServiceWithdrawRequest
  # 4. Sleep 5 seconds
  # 5. User calls LNServiceWithdraw -> Error, expired!

  trace 1 "\n[expired2] ${On_Yellow}${BBlack} Expired 2!                                                                        ${Color_Off}"

  local callbackurl=${1}
  local lnServicePrefix=${2}

  # Service creates LNURL Withdraw
  local createLnurlWithdraw=$(create_lnurl_withdraw "${callbackurl}" 5)
  trace 2 "[expired2] createLnurlWithdraw=${createLnurlWithdraw}"
  local lnurl=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurl")
  #trace 2 "lnurl=${lnurl}"

  local lnurl_withdraw_id=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurlWithdrawId")
  local get_lnurl_withdraw=$(get_lnurl_withdraw ${lnurl_withdraw_id})
  trace 2 "[expired2] get_lnurl_withdraw=${get_lnurl_withdraw}"
  local equals=$(jq --argjson a "${createLnurlWithdraw}" --argjson b "${get_lnurl_withdraw}" -n '$a == $b')
  trace 2 "[expired2] equals=${equals}"
  if [ "${equals}" = "true" ]; then
    trace 2 "[expired2] EQUALS!"
  else
    trace 1 "[expired2] ${On_Red}${BBlack} NOT EQUALS!                                                                          ${Color_Off}"
    return 1
  fi

  # Decode LNURL
  local urlSuffix=$(decode_lnurl "${lnurl}" "${lnServicePrefix}")
  trace 2 "[expired2] urlSuffix=${urlSuffix}"

  # User calls LN Service LNURL Withdraw Request
  local withdrawRequestResponse=$(call_lnservice_withdraw_request "${urlSuffix}")
  trace 2 "[expired2] withdrawRequestResponse=${withdrawRequestResponse}"

  # Create bolt11 for LN Service LNURL Withdraw
  local amount=$(echo "${createLnurlWithdraw}" | jq -r '.result.amount')
  local description=$(echo "${createLnurlWithdraw}" | jq -r '.result.description')
  local invoice=$(create_bolt11 "${amount}" "${description}")
  trace 2 "[expired2] invoice=${invoice}"
  local bolt11=$(echo ${invoice} | jq -r ".bolt11")
  trace 2 "[expired2] bolt11=${bolt11}"

  trace 2 "[expired2] Sleeping 5 seconds..."
  sleep 5

  # User calls LN Service LNURL Withdraw
  local withdrawResponse=$(call_lnservice_withdraw "${withdrawRequestResponse}" "${lnServicePrefix}" "${bolt11}")
  trace 2 "[expired2] withdrawResponse=${withdrawResponse}"

  echo "${withdrawResponse}" | grep -qi "expired"
  if [ "$?" -ne "0" ]; then
    trace 1 "[expired2] ${On_Red}${BBlack} NOT EXPIRED!                                                                         ${Color_Off}"
    return 1
  else
    trace 1 "\n[expired2] ${On_IGreen}${BBlack} SUCCESS!                                                                       ${Color_Off}"
  fi
}

deleted1() {
  # Deleted 1:
  #
  # 1. Create a LNURL Withdraw with expiration=now
  # 2. Get it and compare
  # 3. Delete it
  # 4. Get it and compare
  # 5. User calls LNServiceWithdrawRequest -> Error, deleted!

  trace 1 "\n[deleted1] ${On_Yellow}${BBlack} Deleted 1!                                                                        ${Color_Off}"

  local callbackurl=${1}
  local lnServicePrefix=${2}

  # Service creates LNURL Withdraw
  local createLnurlWithdraw=$(create_lnurl_withdraw "${callbackurl}" 0)
  trace 2 "[deleted1] createLnurlWithdraw=${createLnurlWithdraw}"
  local lnurl=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurl")
  #trace 2 "lnurl=${lnurl}"

  local lnurl_withdraw_id=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurlWithdrawId")
  local get_lnurl_withdraw=$(get_lnurl_withdraw ${lnurl_withdraw_id})
  trace 2 "[deleted1] get_lnurl_withdraw=${get_lnurl_withdraw}"
  local equals=$(jq --argjson a "${createLnurlWithdraw}" --argjson b "${get_lnurl_withdraw}" -n '$a == $b')
  trace 2 "[deleted1] equals=${equals}"
  if [ "${equals}" = "true" ]; then
    trace 2 "[deleted1] EQUALS!"
  else
    trace 1 "[deleted1] ${On_Red}${BBlack} NOT EQUALS!                                                                          ${Color_Off}"
    return 1
  fi

  local delete_lnurl_withdraw=$(delete_lnurl_withdraw ${lnurl_withdraw_id})
  trace 2 "[deleted1] delete_lnurl_withdraw=${delete_lnurl_withdraw}"
  local deleted=$(echo "${get_lnurl_withdraw}" | jq '.result.active = false | del(.result.updatedAt)')
  trace 2 "[deleted1] deleted=${deleted}"

  get_lnurl_withdraw=$(get_lnurl_withdraw ${lnurl_withdraw_id} | jq 'del(.result.updatedAt)')
  trace 2 "[deleted1] get_lnurl_withdraw=${get_lnurl_withdraw}"
  equals=$(jq --argjson a "${deleted}" --argjson b "${get_lnurl_withdraw}" -n '$a == $b')
  trace 2 "[deleted1] equals=${equals}"
  if [ "${equals}" = "true" ]; then
    trace 2 "[deleted1] EQUALS!"
  else
    trace 1 "[deleted1] ${On_Red}${BBlack} NOT EQUALS!                                                                          ${Color_Off}"
    return 1
  fi

  # Delete it twice...
  trace 2 "[deleted1] Let's delete it again..."
  delete_lnurl_withdraw=$(delete_lnurl_withdraw ${lnurl_withdraw_id})
  trace 2 "[deleted1] delete_lnurl_withdraw=${delete_lnurl_withdraw}"
  echo "${delete_lnurl_withdraw}" | grep -qi "already deactivated"
  if [ "$?" -ne "0" ]; then
    trace 1 "[deleted1] ${On_Red}${BBlack} Should return an error because already deactivated!                                 ${Color_Off}"
    return 1
  else
    trace 1 "\n[deleted1] ${On_IGreen}${BBlack} SUCCESS!                                                                       ${Color_Off}"
  fi

  # Decode LNURL
  local urlSuffix=$(decode_lnurl "${lnurl}" "${lnServicePrefix}")
  trace 2 "[deleted1] urlSuffix=${urlSuffix}"

  # User calls LN Service LNURL Withdraw Request
  local withdrawRequestResponse=$(call_lnservice_withdraw_request "${urlSuffix}")
  trace 2 "[deleted1] withdrawRequestResponse=${withdrawRequestResponse}"

  echo "${withdrawRequestResponse}" | grep -qi "Deactivated"
  if [ "$?" -ne "0" ]; then
    trace 1 "[deleted1] ${On_Red}${BBlack} NOT DELETED!                                                                         ${Color_Off}"
    return 1
  else
    trace 1 "\n[deleted1] ${On_IGreen}${BBlack} SUCCESS!                                                                       ${Color_Off}"
  fi
}

deleted2() {
  # Deleted 2:
  #
  # 1. Create a LNURL Withdraw with expiration=now + 5 seconds
  # 2. Get it and compare
  # 5. User calls LNServiceWithdrawRequest
  # 3. Delete it
  # 5. User calls LNServiceWithdraw -> Error, deleted!

  trace 1 "\n[deleted2] ${On_Yellow}${BBlack} Deleted 2!                                                                        ${Color_Off}"

  local callbackurl=${1}
  local lnServicePrefix=${2}

  # Service creates LNURL Withdraw
  local createLnurlWithdraw=$(create_lnurl_withdraw "${callbackurl}" 5)
  trace 2 "[deleted2] createLnurlWithdraw=${createLnurlWithdraw}"
  local lnurl=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurl")
  #trace 2 "lnurl=${lnurl}"

  local lnurl_withdraw_id=$(echo "${createLnurlWithdraw}" | jq -r ".result.lnurlWithdrawId")
  local get_lnurl_withdraw=$(get_lnurl_withdraw ${lnurl_withdraw_id})
  trace 2 "[deleted2] get_lnurl_withdraw=${get_lnurl_withdraw}"
  local equals=$(jq --argjson a "${createLnurlWithdraw}" --argjson b "${get_lnurl_withdraw}" -n '$a == $b')
  trace 2 "[deleted2] equals=${equals}"
  if [ "${equals}" = "true" ]; then
    trace 2 "[deleted2] EQUALS!"
  else
    trace 1 "[deleted2] ${On_Red}${BBlack} NOT EQUALS!                                                                          ${Color_Off}"
    return 1
  fi

  # Decode LNURL
  local urlSuffix=$(decode_lnurl "${lnurl}" "${lnServicePrefix}")
  trace 2 "[deleted2] urlSuffix=${urlSuffix}"

  # User calls LN Service LNURL Withdraw Request
  local withdrawRequestResponse=$(call_lnservice_withdraw_request "${urlSuffix}")
  trace 2 "[deleted2] withdrawRequestResponse=${withdrawRequestResponse}"

  # Create bolt11 for LN Service LNURL Withdraw
  local amount=$(echo "${createLnurlWithdraw}" | jq -r '.result.amount')
  local description=$(echo "${createLnurlWithdraw}" | jq -r '.result.description')
  local invoice=$(create_bolt11 "${amount}" "${description}")
  trace 2 "[deleted2] invoice=${invoice}"
  local bolt11=$(echo ${invoice} | jq -r ".bolt11")
  trace 2 "[deleted2] bolt11=${bolt11}"

  local delete_lnurl_withdraw=$(delete_lnurl_withdraw ${lnurl_withdraw_id})
  trace 2 "[deleted2] delete_lnurl_withdraw=${delete_lnurl_withdraw}"
  local deleted=$(echo "${get_lnurl_withdraw}" | jq '.result.active = false')
  trace 2 "[deleted2] deleted=${deleted}"

  # User calls LN Service LNURL Withdraw
  local withdrawResponse=$(call_lnservice_withdraw "${withdrawRequestResponse}" "${lnServicePrefix}" "${bolt11}")
  trace 2 "[deleted2] withdrawResponse=${withdrawResponse}"

  echo "${withdrawResponse}" | grep -qi "Deactivated"
  if [ "$?" -ne "0" ]; then
    trace 1 "[deleted2] ${On_Red}${BBlack} NOT DELETED!                                                                         ${Color_Off}"
    return 1
  else
    trace 1 "\n[deleted2] ${On_IGreen}${BBlack} SUCCESS!                                                                       ${Color_Off}"
  fi
}

TRACING=2

trace 2 "${Color_Off}"
date

# Install needed packages
trace 2 "\n${BCyan}Installing needed packages...${Color_Off}"
apk add curl jq

# Initializing test variables
trace 2 "\n${BCyan}Initializing test variables...${Color_Off}"
callbackservername="cb"
callbackserverport="1111"
callbackurl="http://${callbackservername}:${callbackserverport}"

# Get config from lnurl cypherapp
trace 2 "\n${BCyan}Getting configuration from lnurl cypherapp...${Color_Off}"
data='{"id":0,"method":"getConfig","params":[]}'
lnurlConfig=$(curl -sd "${data}" -H "Content-Type: application/json" lnurl:8000/api)
trace 2 "lnurlConfig=${lnurlConfig}"
lnServicePrefix=$(echo "${lnurlConfig}" | jq -r '.result | "\(.LN_SERVICE_SERVER):\(.LN_SERVICE_PORT)"')
trace 2 "lnServicePrefix=${lnServicePrefix}"

happy_path "${callbackurl}" "${lnServicePrefix}" \
&& expired1 "${callbackurl}" "${lnServicePrefix}" \
&& expired2 "${callbackurl}" "${lnServicePrefix}" \
&& deleted1 "${callbackurl}" "${lnServicePrefix}" \
&& deleted2 "${callbackurl}" "${lnServicePrefix}"
