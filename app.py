#version5 imports R libraries: os, subprocess / runs the R Script to transform the data [WIP]
#stdlibs
import logging, time, json, os, subprocess

#third-party libraries
import requests

#local imports
from upload_to_s3 import upload_to_s3
from emailapp import email_app
import config

logging.info("Starting....")

if __name__ == "__main__":
    # exception block to detect errors while fetching data
    try:
        #runs the R Script
        this_file = os.path.abspath(__file__)
        os.chdir(os.path.dirname(this_file))
        subprocess.run(["Rscript", "test_csv_export_v2.R"])

    except Exception as err:
        logging.error("Error fetching data: %s" % str(err) )
        # calls the email function to send a notification 
        email_app()

    # data processing
    #body = json.dumps(json_response) Not needed? We're no longer exporting to .json
    logging.info("starting upload")

    try:
        # upload_to_s3(body=body, filename="covid_agg.csv") Removed body=body    
        upload_to_s3(filename="covid_agg.csv") 
    except Exception as err:
        logging.error("Error uploading data: %s" % str(err)) 
    
    logging.info("finished upload")

        