# SimpleScanner
Simple Scanner, to use with haveibeenpwned.com or hacked-emails.com for now.

The results are stored in result.json

# Requirements

This script requires curl and jq.
```
sudo apt-get install curl jq
```
# Download
```
git clone https://github.com/Emilien942702/SimpleScanner
```
# Usage
```
cd SimpleScanner/
sudo bash SimpleScanner.sh database.txt
```
# Options
The script takes as argument the file in which your emails are stored, one by line.

You can choose between haveibeenpwned or hacked-emails.

hacked-emails.com blocks at around 300 per day.

The output is a json file readable by any [json online viewer](http://json.bloople.net/)

# Sources
[haveibeenpwned.com](https://haveibeenpwned.com/)

[hacked-emails.com](https://hacked-emails.com/)
