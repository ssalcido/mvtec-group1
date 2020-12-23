# mvtec-group1
 Repository for the first trimester’s final project

- **app.py**
    - This is our main application. It contains required libraries, runs scripts to extract raw data, transform it, upload it to AWS S3, and send notifications in case of errors while fetching data.
- **config.py**
    - Config specs with logging info for AWS/S3
- **emailapp.py**
    - Script to send notifications emails with Python
    - `en var` (environment variable) code to call the Gmail password on Heroku config vars.
- **pipeline_flowchart**
    - A flow diagram visualising the pipeline.
- **Procfile**
    - Required by Heroku (specifies the commands that are executed by the app on startup). In this case is empty because we'll use the *Heroku scheduler* add-on.
- **requirements.txt**
    - Indicates required libraries on Heroku
- **upload_to_s3.py**
    - Uploads the database to AWS/S3

![pipeline](https://github.com/ssalcido/mvtec-group1/blob/main/pipeline_flowchart.png?raw=true)