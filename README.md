# SimpleScanner
Simple Scanner, to use with haveibeenpwned.com, hacked-emails.com or weleakinfo.com for now. 

Provided a database of emails, it outputs for each email compromised websites and pastes from haveibeenpwned.com or information from hacked-emails.com or weleakinfo.com. 

It can also, if emails are firstname.lastname@domain.com or lastname.firstname@domain.com perform a name search on weleakinfo.com

# haveibeenpwned.com

For compromised websites in which the email appears, retrieves Name and DataClasses (what has been hacked) from API
```
  {
    "Name": "GeekedIn",
    "DataClasses": [
      "Email addresses",
      "Geographic locations",
      "Names",
      "Professional skills",
      "Usernames",
      "Years of professional experience"
      ]
  }
```

For pastes in which the emails appears, retrieves URL and Title from API
```
  {
    "Id": "http://pastebin.com/i8sZ6P4Q",
    "Title": "LizardSquad Database"
  }
```

# hacked-emails.com

Retrieves Title, Details and Source URL from API
```
  {
    "title": "MongoDB Crawlers Pack - United States of America Server",
    "details": "https://hacked-emails.com/leak/5726936904e470f90e81/mongodb-crawlers-pack-united-states-of-america-server",
    "source_url": "#"
  }
```

# weleakinfo.com

Displays a menu for the possibility to use the name search or not, and the formatting of the emails. Only displays the name of the website
```
[
  {
    "Sites by email": [
      {
        "Geekedin.net 08-2016": 1
      }
    ]
  },
  {
    "Sites by name": [
      {
        "Xsplit.com 2015": 1,
        "Dominos (FR NL BE EN) 06-2014": 2
      }
    ]
  }
]
```



The results are stored in result.json.


# Requirements

This script requires curl for API requests, jq for output in JSON and moreutils for overwriting with jq handling.
```
sudo apt-get install curl jq moreutils
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

haveibeenpwned.com's API blocks if you do more than 1 request per 1500ms.

hacked-emails.com's API blocks at around 300 requests per day.

weleakinfo.com's API blocks at 3 request per second

The output is a json file readable by any [json online viewer](http://json.bloople.net/)

# Sources
[haveibeenpwned.com](https://haveibeenpwned.com/)

[hacked-emails.com](https://hacked-emails.com/)

[weleakinfo.com](https://weleakinfo.com)
