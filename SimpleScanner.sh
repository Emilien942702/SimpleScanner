database=$1
nbrlignes=$(wc -l $database | cut -d ' ' -f 1)
echo Which database should I use ?
echo 1. haveibeenpwned.com
echo 2. hacked-emails.com
read option
if [[ $option == "1" ]]; then
	url=https://haveibeenpwned.com/api/v2/pasteaccount/
elif [[ $option == "2" ]]; then
	url='https://hacked-emails.com/api?q='

fi
for ligne in `seq 1 $nbrlignes`;
do
	ligne=`head -n $ligne $database | tail -1`
	urlbis=$url$ligne
	urlbis=${urlbis%$'\r'}
	temp=`curl -i -H "Accept: application/json" -H "Content-Type: application/json" -X GET $urlbis`
	echo -e "$ligne\n$temp" >> results.txt
	sleep 2
done