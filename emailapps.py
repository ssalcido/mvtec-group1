# Don't name it email.py or it will cause an error!
# version 2 Takes credentials (Gmail password) from an environment variable / added multiple recipients
import smtplib, ssl
import os

# env var to call the Gmail password on Heroku config vars
password= os.environ.get('password')

# Python function for sending emails
def emailfetch() :
    port = 465  # For SSL
    smtp_server = "smtp.gmail.com"
    sender_email = "mvtec.learning@gmail.com"  # Enter your address
    receiver_email = ['mvtec.learning@gmail.com', 'san.salcido@gmail.com']  # Enter receiver address
    message = """\
    Subject: Hi there mvtec-group 1!  
    The app.py catched an error while fetching the data."""

    context = ssl.create_default_context()
    with smtplib.SMTP_SSL(smtp_server, port, context=context) as server:
        server.login(sender_email, password)
        server.sendmail(sender_email, receiver_email, message)

def emailupload() :
    port = 465  # For SSL
    smtp_server = "smtp.gmail.com"
    sender_email = "mvtec.learning@gmail.com"  # Enter your address
    receiver_email = ['mvtec.learning@gmail.com', 'san.salcido@gmail.com']  # Enter receiver address
    message = """\
    Subject: Hi there mvtec-group 1!  
    The app.py catched an error while uploading the data."""

    context = ssl.create_default_context()
    with smtplib.SMTP_SSL(smtp_server, port, context=context) as server:
        server.login(sender_email, password)
        server.sendmail(sender_email, receiver_email, message)