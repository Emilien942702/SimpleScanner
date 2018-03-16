database=$1
nbrlignes=$(grep -c ^ $database)
echo Which database should I use ?
echo 1. haveibeenpwned.com
echo 2. hacked-emails.com
read option
if [[ $option == "1" ]]; then
	for ligne in `seq 1 $nbrlignes`;
	do
		touch tempsite
		touch temppaste
		touch newresult
		vraieligne=`head -n $ligne $database | tail -1`
		vraieligne=${vraieligne%$'\r'}
		urlpaste=https://haveibeenpwned.com/api/v2/pasteaccount/$vraieligne'?includeUnverified=true'
		urlpaste="$(echo -e "${urlpaste}" | tr -d '[:space:]')"
		resultpaste=`curl -s -H "Accept: application/json" -H "Content-Type: application/json" -X GET $urlpaste`
		if [[ `echo $resultpaste | grep 'Rate limit exceeded' -c` -ne 0 ]]; then
			echo Rate limit exceeded
			sleep 2
			resultpaste=`curl -s -H "Accept: application/json" -H "Content-Type: application/json" -X GET $urlpaste`
			if [[ `echo $resultpaste | grep 'Rate limit exceeded' -c` -ne 0 ]]; then
				echo You just got timed out ... Try later 
				echo "Last mail tested was" head -n $ligne-1
				cat result.json | jq '{Emails:[.]}' > result.json
				sed -i 's/\\t//g' result.json
				rm tempsite temppaste newresult
				exit
			fi
		fi
		if [[ `echo $resultpaste | grep '\[{' -c` -ne 0 ]]; then
			echo $resultpaste | jq 'map(if .Source=="Pastebin" then .Id="http://pastebin.com/"+.Id else . end)' | jq 'del (.[] | .Source, .Date, .EmailCount)' | jq '{Pastes:[.[]]}' > temppaste
		fi
		sleep 2
		urlbreachedaccount=https://haveibeenpwned.com/api/v2/breachedaccount/$vraieligne
		urlbreachedaccount="$(echo -e "${urlbreachedaccount}" | tr -d '[:space:]')"
		resultbreachedaccount=`curl -s -H "Accept: application/json" -H "Content-Type: application/json" -X GET $urlbreachedaccount`
		if [[ `echo $resultbreachedaccount | grep '\[{' -c` -ne 0 ]]; then
			echo $resultbreachedaccount | jq 'del (.[] | .Title, .Domain, .BreachDate, .AddedDate, .ModifiedDate, .PwnCount, .Description, .IsVerified, .IsFabricated, .IsSensitive, .IsActive, .IsRetired, .IsSpamList, .LogoType)'| jq '{Sites:[.[]]}' > tempsite
		fi
		if [[ -s temppaste && -s tempsite ]]; then
			jq -s '[.[]]' tempsite temppaste | jq "{\"$vraieligne\":[.]}" > newresult
			rm tempsite
			rm temppaste
		elif [[ -s temppaste && ! -s tempsite ]]; then
			cat temppaste | jq "{\"$vraieligne\":[.]}" > newresult
			rm temppaste
		elif [[ ! -s temppaste && -s tempsite ]]; then
			cat tempsite | jq "{\"$vraieligne\":[.]}" > newresult
			rm tempsite
		fi
			if [[ -s newresult ]]; then
				echo Found entries for $vraieligne
				if [[ ! -s result.json ]]; then
					cat newresult > result.json
				else
				 jq -s 'add' result.json newresult > temp
				 cat temp > result.json
				 rm temp
				fi
			rm newresult
			fi
		echo $ligne out of $nbrlignes
		sleep 2
	done
elif [[ $option == "2" ]]; then
	url='https://hacked-emails.com/api?q='
	for ligne in `seq 1 $nbrlignes`;
	do
		touch temp
		vraieligne=`head -n $ligne $database | tail -1`
		vraieligne=${vraieligne%$'\r'}
		url='https://hacked-emails.com/api?q='$vraieligne
		url="$(echo -e "${url}" | tr -d '[:space:]')"
		result=`curl -s -H "Accept: application/json" -H "Content-Type: application/json" -X GET $url`
		if [[ `echo $result | grep -w "apilimit" -c` -ne 0 ]]; then
			echo "Api limit reached for the day ..."
			last=`expr $ligne - 1`
			echo "Last mail tested was" 
			head -n $last $database | tail -1
			rm temp
			cat result.json | jq '{Emails:[.]}' > result.json
			sed -i 's/\\t//g' result.json
			exit
		fi
		if [[ `echo $result | grep -w "found" -c` -ne 0 ]]; then
			echo $result | jq 'del(.| .status,.results,.query,.data[].author,.data[].verified,.data[].date_created,.data[].date_leaked,.data[].emails_count,.data[].source_lines,.data[].source_size,.data[].source_network,.data[].source_provider)' | jq '{Results:[.[]]}' > temp
		fi
		if [[ -s temp ]]; then
			cat temp | jq "{\"$vraieligne\":[.]}" > newresult
		fi
		if [[ -s newresult ]]; then
				echo Found entries for $vraieligne
				if [[ ! -s result.json ]]; then
					cat newresult > result.json
				else
				 jq -s 'add' result.json newresult > temp
				 cat temp > result.json
				 rm temp
				fi
			rm newresult
			fi
		echo $ligne out of $nbrlignes
		sleep 2
	done
fi
cat result.json | jq '{Emails:[.]}' > result.json
sed -i 's/\\t//g' result.json
