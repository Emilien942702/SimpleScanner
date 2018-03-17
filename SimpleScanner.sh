database=$1
nbrlignes=$(grep -c ^ $database)
echo Which database should I use ?
echo 1. haveibeenpwned.com
echo 2. hacked-emails.com
echo 3. weleakinfo.com
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
		if [[ `echo $resultpaste | grep '\[{' -c` -ne 0 ]]; then
			echo $resultpaste | jq 'map(if .Source=="Pastebin" then .Id="http://pastebin.com/"+.Id else . end)' | jq 'del (.[] | .Source, .Date, .EmailCount)' | jq '{Pastes:[.[]]}' > temppaste
		fi
		urlbreachedaccount=https://haveibeenpwned.com/api/v2/breachedaccount/$vraieligne
		urlbreachedaccount="$(echo -e "${urlbreachedaccount}" | tr -d '[:space:]')"
		resultbreachedaccount=`curl -s -H "Accept: application/json" -H "Content-Type: application/json" -X GET $urlbreachedaccount`
		if [[ `echo $resultbreachedaccount | grep 'Rate limit exceeded' -c` -ne 0 ]]; then
			echo Rate limit exceeded
			sleep 1.6
			resultbreachedaccount=`curl -s -H "Accept: application/json" -H "Content-Type: application/json" -X GET $urlbreachedaccount`
			if [[ `echo $resultbreachedaccount | grep 'Rate limit exceeded' -c` -ne 0 ]]; then
				echo "You just got timed out ... Try later"
				last=`expr $ligne - 1`
				echo "Last mail tested was" 
				head -n $last $database | tail -1
				cat result.json | jq '{Emails:[.]}' | sponge result.json
				sed -i 's/\\t//g' result.json
				rm temppaste tempsite newresult
				exit
			fi
		fi
		if [[ `echo $resultbreachedaccount | grep '\[{' -c` -ne 0 ]]; then
			echo $resultbreachedaccount | jq 'del (.[] | .Title, .Domain, .BreachDate, .AddedDate, .ModifiedDate, .PwnCount, .Description, .IsVerified, .IsFabricated, .IsSensitive, .IsActive, .IsRetired, .IsSpamList, .LogoType)'| jq '{Sites:[.[]]}' > tempsite
		fi
		if [[ -s temppaste && -s tempsite ]]; then
			jq -s '[.[]]' tempsite temppaste | jq "{\"$vraieligne\":[.]}" > newresult
		elif [[ -s temppaste && ! -s tempsite ]]; then
			cat temppaste | jq "{\"$vraieligne\":[.]}" > newresult
		elif [[ ! -s temppaste && -s tempsite ]]; then
			cat tempsite | jq "{\"$vraieligne\":[.]}" > newresult
		fi
			if [[ -s newresult ]]; then
				echo Found entries for $vraieligne
				if [[ ! -s result.json ]]; then
					cat newresult > result.json
				else
				 jq -s 'add' result.json newresult | sponge result.json
				fi
			fi
		rm tempsite temppaste newresult 2> /dev/null
		echo $ligne out of $nbrlignes
		sleep 1.6
	done
elif [[ $option == "2" ]]; then
	for ligne in `seq 1 $nbrlignes`;
	do
		touch newresult
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
			rm newresult
			cat result.json | jq '{Emails:[.]}' | sponge result.json 2> /dev/null
			sed -i 's/\\t//g' result.json 2> /dev/null
			exit
		fi
		if [[ `echo $result | grep -w "found" -c` -ne 0 ]]; then
			echo $result | jq 'del(.| .status,.results,.query,.data[].author,.data[].verified,.data[].date_created,.data[].date_leaked,.data[].emails_count,.data[].source_lines,.data[].source_size,.data[].source_network,.data[].source_provider)' | jq '{Results:[.[]]}' > newresult
		fi
		if [[ -s newresult ]]; then
			cat newresult | jq "{\"$vraieligne\":[.]}" | sponge newresult
			echo Found entries for $vraieligne
			if [[ ! -s result.json ]]; then
				cat newresult > result.json
			else
			 jq -s 'add' result.json newresult | sponge result.json
			fi
		fi
		rm newresult		
		echo $ligne out of $nbrlignes
	done
elif [[ $option == "3" ]]; then
	echo "Want to try the name search ? [y/n]"
	read choice
	if [[ $choice == "y" ]]; then
		echo "What are your emails made of ?"
		echo "1. firstname.lastname@domain.com"
		echo "2. lastname.firstname@domain.com"
		read choice2
		for ligne in `seq 1 $nbrlignes`;
		do
			touch tempsite
			touch tempname
			touch newresult
			vraieligne=`head -n $ligne $database | tail -1`
			vraieligne=${vraieligne%$'\r'}
			if [[ $choice2 == "1" ]]; then
				prenom=`echo $vraieligne | cut -d '.' -f 1`
				nom=`echo $vraieligne | cut -d '.' -f 2 | cut -d '@' -f 1`
			elif [[ $choice2 == "2" ]]; then
				prenom=`echo $vraieligne | cut -d '.' -f 2 | cut -d '@' -f 1`
				nom=`echo $vraieligne | cut -d '.' -f 1`
			fi
			urlsite='https://api.weleakinfo.com/v2/public/email/'$vraieligne
			urlsite="$(echo -e "${urlsite}" | tr -d '[:space:]')"
			resultsite=`curl -s --user-agent "Mozilla 5.0" -H "Accept: application/json" -H "Content-Type: application/json" -X GET $urlsite`
			if [[ `echo $resultsite | grep 'You are being rate limited' -c` -ne 0 ]]; then
				echo "Rate limit exceeded"
				echo "190 seconds cooldown"
				sleep 190
				resultsite=`curl -s --user-agent "Mozilla 5.0" -H "Accept: application/json" -H "Content-Type: application/json" -X GET $urlsite`
				if [[ `echo $resultsite | grep 'You are being rate limited' -c` -ne 0 ]]; then
					echo You just got timed out ... Try later 
					last=`expr $ligne - 1`
					echo "Last mail tested was" 
					head -n $last $database | tail -1
					cat result.json | jq '{Emails:[.]}' | sponge result.json
					sed -i 's/\\t//g' result.json
					rm newresult
					exit
				fi
			fi
			if [[ `echo $resultsite | grep -w "\"Hits\": 0," -c` -eq 0 ]]; then
				echo $resultsite | jq 'del(.Response, .Time, .Hits,.Unique)' | jq '{"Sites by email":[.[]]}' > tempsite
			fi
			urlname='https://api.weleakinfo.com/v2/public/name/'$prenom\_$nom
			urlname="$(echo -e "${urlname}" | tr -d '[:space:]')"
			resultname=`curl -s --user-agent "Mozilla 5.0" -H "Accept: application/json" -H "Content-Type: application/json" -X GET $urlname`
			if [[ `echo $resultname | grep 'You are being rate limited' -c` -ne 0 ]]; then
				echo "Rate limit exceeded"
				echo "190 seconds cooldown"
				sleep 190
				resultname=`curl -s --user-agent "Mozilla 5.0" -H "Accept: application/json" -H "Content-Type: application/json" -X GET $urlname`
				if [[ `echo $resultname | grep 'You are being rate limited' -c` -ne 0 ]]; then
					echo You just got timed out ... Try later 
					last=`expr $ligne - 1`
					echo "Last mail tested was" 
					head -n $last $database | tail -1
					cat result.json | jq '{Emails:[.]}' | sponge result.json
					sed -i 's/\\t//g' result.json
					rm newresult
					exit
				fi
			fi
			if [[ `echo $resultname | grep -w "\"Hits\": 0," -c` -eq 0 && `echo $resultname | grep -w "Bad Request" -c` -eq 0 ]]; then
				echo $resultname | jq 'del(.Response, .Time, .Hits,.Unique)' | jq '{"Sites by name":[.[]]}' > tempname
			fi
			if [[ -s tempname && -s tempsite ]]; then
				jq -s '[.[]]' tempsite tempname | jq "{\"$vraieligne\":[.]}" > newresult
			elif [[ -s tempname && ! -s tempsite ]]; then
				cat tempname | jq "{\"$vraieligne\":[.]}" > newresult
			elif [[ ! -s tempname && -s tempsite ]]; then
				cat tempsite | jq "{\"$vraieligne\":[.]}" > newresult
			fi
			if [[ -s newresult ]]; then
				echo Found entries for $vraieligne
				if [[ ! -s result.json ]]; then
					cat newresult > result.json
				else
					 jq -s 'add' result.json newresult | sponge result.json
				fi
			fi
			rm tempsite tempname newresult 2> /dev/null
			echo $ligne out of $nbrlignes
	done
	elif [[ $choice == "n" ]]; then
		for ligne in `seq 1 $nbrlignes`;
		do
			touch newresult
			vraieligne=`head -n $ligne $database | tail -1`
			vraieligne=${vraieligne%$'\r'}
			url='https://api.weleakinfo.com/v2/public/email/'$vraieligne
			url="$(echo -e "${url}" | tr -d '[:space:]')"
			result=`curl -s --user-agent "Mozilla 5.0" -H "Accept: application/json" -H "Content-Type: application/json" -X GET $url`
			if [[ `echo $result | grep 'You are being rate limited' -c` -ne 0 ]]; then
				echo Rate limit exceeded
				echo 190 seconds cooldown
				sleep 190
				result=`curl -s --user-agent "Mozilla 5.0" -H "Accept: application/json" -H "Content-Type: application/json" -X GET $url`
				if [[ `echo $result | grep 'You are being rate limited' -c` -ne 0 ]]; then
					echo You just got timed out ... Try later 
					last=`expr $ligne - 1`
					echo "Last mail tested was" 
					head -n $last $database | tail -1
					cat result.json | jq '{Emails:[.]}' | sponge result.json
					sed -i 's/\\t//g' result.json
					rm newresult
					exit
				fi
			fi
			if [[ `echo $result | grep -w "\"Hits\": 0," -c` -eq 0 ]]; then
				echo $result | jq 'del(.Response, .Time, .Hits,.Unique)' | jq '{Results:[.[]]}' > newresult
			fi
			if [[ -s newresult ]]; then
				cat newresult | jq "{\"$vraieligne\":[.]}" | sponge newresult
				echo Found entries for $vraieligne
				if [[ ! -s result.json ]]; then
					cat newresult > result.json
				else
				 jq -s 'add' result.json newresult | sponge result.json
				fi
			fi
			rm newresult		
			echo $ligne out of $nbrlignes
		done
	fi
fi
cat result.json | jq '{Emails:[.]}' | sponge result.json
sed -i 's/\\t//g' result.json
