#version5 imports R libraries: os, subprocess / runs the R Script to transform the data [WIP]
#stdlibs
import logging, time, json, os, subprocess, csv

#third-party libraries
import requests

#local imports
from upload_to_s3 import upload_to_s3
from emailapps import emailfetch, emailupload
import config

logging.info("Starting....")

if __name__ == "__main__":
    # exception block to detect errors while fetching data
    try:
        #runs the R Script
        this_file = os.path.abspath(__file__)
        os.chdir(os.path.dirname(this_file))
        subprocess.run(["Rscript", "PredictiveDaily.R"])

    except Exception as err:
        logging.error("Error fetching data: %s" % str(err) )
        # if error, calls the emailfetch function to send a notification 
        emailfetch()

    # creates a .csv file from the R Script 
    with open("forecasts.csv", 'r', encoding="utf-8") as f:
        body = f.read()
    
    logging.info("starting upload")

    try:
        upload_to_s3(body=body, filename="forecasts.csv")    
    except Exception as err:
        logging.error("Error uploading data: %s" % str(err))
        # if error, calls the emailupload function to send a notification 
        emailupload()
    
    logging.info("finished upload")