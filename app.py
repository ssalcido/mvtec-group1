#version4 with except blocks, imports the emailapp, adding the R Script
#stdlibs
import logging, time, json

#third-party libraries
import requests

#local imports
from upload_to_s3 import upload_to_s3
from emailapp import email_app
import config

logging.info("Starting....")

if __name__ == "__main__":
    # exception block to detect errors in fetching data
    try:
        r = requests.get('https://coviddata.github.io/coviddata/v1/countries/stats.json')
        json_response = r.json()
    except Exception as err:
        logging.error("Error fetching data: %s" % str(err) )
        # call the email function so it send a notification if error
        email_app()

    # data processing
    body = json.dumps(json_response)
    logging.info("starting upload")

    try:
        upload_to_s3(body=body, filename="data.json")       
    except Exception as err:
        logging.error("Error uploading data: %s" % str(err)) 
    
    logging.info("finished upload")

        