######################################################################################################################
# Copyright 2013 Amazon Technologies, Inc.
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in
# compliance with the License.
#
# You may obtain a copy of the License at:http://aws.amazon.com/apache2.0 This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#
# See the License for the specific language governing permissions and limitations under the License.
######################################################################################################################

require 'gyoku'
require 'digest'
require 'openssl'
require 'net/http'
require 'json'

# An enumeration of the types of API this sample code supports
module AGCODServiceOperation
    ActivateGiftCard        = 'ActivateGiftCard'
    DeactivateGiftCard      = 'DeactivateGiftCard'
    ActivationStatusCheck   = 'ActivationStatusCheck'
    CreateGiftCard          = 'CreateGiftCard'
    CancelGiftCard          = 'CancelGiftCard'
    GetGiftCardActivityPage = 'GetGiftCardActivityPage'
end

# An enumeration of supported formats for the payload
module PayloadType
    JSON                    = 'JSON'
    XML                     = 'XML'
end

module App
    #Static headers used in the request
    ACCEPT_HEADER = "accept"
    CONTENT_HEADER = "content-type"
    HOST_HEADER = "host"
    XAMZDATE_HEADER = "x-amz-date"
    XAMZTARGET_HEADER = "x-amz-target"
    AUTHORIZATION_HEADER = "Authorization"

    #Static format parameters
    DATE_FORMAT = "%Y%m%dT%H%M%SZ"

    #Signature calculation related parameters
    #HMAC_SHA256_ALGORITHM = "HmacSHA256"
    #HASH_SHA256_ALGORITHM = "SHA-256"
    AWS_SHA256_ALGORITHM = "AWS4-HMAC-SHA256"
    KEY_QUALIFIER = "AWS4"
    TERMINATION_STRING = "aws4_request"

    #User and instance parameters
    AWS_KEY_ID = "" # Your KeyID
    AWS_SECRET_KEY = "" # Your Key
    DATE_TIME_STRING = Time.now.utc.strftime(DATE_FORMAT)  # e.g. "20140630T224526Z"

    #Service and target (API) parameters
    REGION_NAME = "us-east-1" #lowercase!  Ref http://docs.aws.amazon.com/general/latest/gr/rande.html
    SERVICE_NAME = "AGCODService"

    #Payload parameters
    PARTNER_ID = ""
    REQUEST_ID = ""
    CARD_NUMBER = ""
    AMOUNT = 20
    CURRENCY_CODE = "USD"

    #Additional payload parameters for CancelGiftCard
    GC_ID = ""

    #Additional payload parameters for GetGiftCardActivityPage
    PAGE_INDEX = 0
    PAGE_SIZE = 1
    UTC_START_DATE = "" #"yyyy-MM-ddTHH:mm:ss eg. 2013-06-01T23:10:10"
    UTC_END_DATE = "" #"yyyy-MM-ddTHH:mm:ss eg. 2013-06-01T23:15:10"
    SHOW_NOOPS = true

    #Parameters that specify what format the payload should be in and what fields will
    #be in the payload, based on the selected operation.
    MSG_PAYLOAD_TYPE = PayloadType::XML
    #MSG_PAYLOAD_TYPE = PayloadType::JSON
    SERVICE_OPERATION = AGCODServiceOperation::CreateGiftCard
    #SERVICE_OPERATION = AGCODServiceOperation::CancelGiftCard
    #SERVICE_OPERATION = AGCODServiceOperation::ActivateGiftCard
    #SERVICE_OPERATION = AGCODServiceOperation::DeactivateGiftCard
    #SERVICE_OPERATION = AGCODServiceOperation::ActivationStatusCheck
    #SERVICE_OPERATION = AGCODServiceOperation::GetGiftCardActivityPage

    #Parameters used in the message header
    HOST = "agcod-v2-gamma.amazon.com" #Refer to the AGCOD tech spec for a list of end points based on region/environment
    PROTOCOL = "https"
    QUERY_STRING = ""    # empty
    REQUEST_URI = "/" + SERVICE_OPERATION
    SERVICE_TARGET = "com.amazonaws.agcod.AGCODService" + "." + SERVICE_OPERATION
    HOST_NAME = PROTOCOL + "://" + HOST + REQUEST_URI
end


# Creates a dict containing the data to be used to form the request payload.
# @return the populated dict of data
def buildPayloadContent()
    params = {:partnerId => App::PARTNER_ID}
    if App::SERVICE_OPERATION == AGCODServiceOperation::ActivateGiftCard
        params['activationRequestId'] = App::REQUEST_ID
        params['cardNumber']   = App::CARD_NUMBER
        params['value']        = {'currencyCode' => App::CURRENCY_CODE, 'amount' => App::AMOUNT}

    elsif App::SERVICE_OPERATION == AGCODServiceOperation::DeactivateGiftCard
        params['activationRequestId'] = App::REQUEST_ID
        params['cardNumber']   = App::CARD_NUMBER

    elsif App::SERVICE_OPERATION == AGCODServiceOperation::ActivationStatusCheck
        params['statusCheckRequestId'] = App::REQUEST_ID
        params['cardNumber']   = App::CARD_NUMBER

    elsif App::SERVICE_OPERATION == AGCODServiceOperation::CreateGiftCard
        params['creationRequestId'] = App::REQUEST_ID
        params['value']        = {'currencyCode' => App::CURRENCY_CODE, 'amount' => App::AMOUNT}

    elsif App::SERVICE_OPERATION == AGCODServiceOperation::CancelGiftCard
        params['creationRequestId'] = App::REQUEST_ID
        params['gcId']         = App::GC_ID

    elsif App::SERVICE_OPERATION == AGCODServiceOperation::GetGiftCardActivityPage
        params['requestId']    = App::REQUEST_ID
        params['utcStartDate'] = App::UTC_START_DATE
        params['utcEndDate']   = App::UTC_END_DATE
        params['pageIndex']    = App::PAGE_INDEX
        params['pageSize']     = App::PAGE_SIZE
        params['showNoOps']    = App::SHOW_NOOPS

    else
        raise "IllegalArgumentException"
        
    end

    request = App::SERVICE_OPERATION + "Request"
    {request => params}
end


# Sets the payload to be the requested encoding and creates the payload based on the static parameters.
# @return A tuple including the payload to be sent to the AGCOD service and the content type
def setPayload()
    #Set payload based on operation and format
    payload_dict = buildPayloadContent()
    if App::MSG_PAYLOAD_TYPE == PayloadType::XML
        contentType = "charset=UTF-8"
        payload = Gyoku.xml(payload_dict)
    elsif App::MSG_PAYLOAD_TYPE == PayloadType::JSON
        contentType = "application/json"
        # strip operation specifier from JSON payload
        operation_content_dict = payload_dict[payload_dict.keys.first]
        payload = JSON.dump(operation_content_dict)
    else
        raise "IllegalPayloadType"
    end
    return payload, contentType
end


# Creates a canonical request based on set static parameters
# http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
#
# @param payload - The payload to be sent to the AGCOD service
# @param contentType - the wire format of content to be posted
# @return The whole canonical request string to be used in Task 2
def buildCanonicalRequest(payload, contentType)
    #Create a SHA256 hash of the payload, used in authentication
    payloadHash = hashstr(payload)

    #Canonical request headers should be sorted by lower case character code
    canonicalRequest = "POST\n" \
        + App::REQUEST_URI + "\n" \
        + App::QUERY_STRING + "\n" \
        + App::ACCEPT_HEADER + ":" + contentType + "\n" \
        + App::CONTENT_HEADER + ":" + contentType + "\n" \
        + App::HOST_HEADER + ":" + App::HOST + "\n" \
        + App::XAMZDATE_HEADER + ":" + App::DATE_TIME_STRING + "\n" \
        + App::XAMZTARGET_HEADER + ":" + App::SERVICE_TARGET + "\n" \
        + "\n" \
        + App::ACCEPT_HEADER + ";" + App::CONTENT_HEADER + ";" + App::HOST_HEADER + ";" + App::XAMZDATE_HEADER + ";" + App::XAMZTARGET_HEADER + "\n" \
        + payloadHash
    return canonicalRequest
end



# Uses the previously calculated canonical request to create a single "String to Sign" for the request
# http://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
#
# @param canonicalRequestHash - SHA256 hash of the canonical request
# @param dateString - The short 8 digit format for an x-amz-date
# @return The "String to Sign" used in Task 3
def buildStringToSign(canonicalRequestHash, dateString)
    stringToSign = App::AWS_SHA256_ALGORITHM + "\n" \
        + App::DATE_TIME_STRING + "\n" \
        + dateString + "/" + App::REGION_NAME + "/" + App::SERVICE_NAME + "/" + App::TERMINATION_STRING + "\n" \
        + canonicalRequestHash
    return stringToSign
end


# Create a series of Hash-based Message Authentication Codes for use in the final signature
#
# @param data - String to be Hashed
# @param bkey - Key used in signing
# @return Byte string of resultant hash
def hmac_binary(data, bkey)
    return OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, bkey, data)
end


# This function uses given parameters to create a derived key based on the secret key and parameters related to the call
# http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
#
# @param dateString - The short 8 digit format for an x-amz-date
# @return The derived key used in creating the final signature
def buildDerivedKey(dateString)
    signatureAWSKey = App::KEY_QUALIFIER + App::AWS_SECRET_KEY

    #Calculate the derived key from given values
    derivedKey = hmac_binary(App::TERMINATION_STRING,
            hmac_binary(App::SERVICE_NAME,
            hmac_binary(App::REGION_NAME,
            hmac_binary(dateString, signatureAWSKey))))
    return derivedKey
end


# Calculates the signature to put in the POST message header 'Authorization'
# http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
#
# @param stringToSign - The entire "String to Sign" calculated in Task 2
# @param dateString - The short 8 digit format for an x-amz-date
# @return The whole field to be used in the Authorization header for the message
def buildAuthSignature(stringToSign, dateString)
    #Use derived key and "String to Sign" to make the final signature
    derivedKey = buildDerivedKey(dateString)

    finalSignature = hmac_binary(stringToSign, derivedKey)

    signatureString = finalSignature.unpack('H*').first
    authorizationValue = App::AWS_SHA256_ALGORITHM \
        + " Credential=" + App::AWS_KEY_ID + "/" \
        + dateString + "/" \
        + App::REGION_NAME + "/" \
        + App::SERVICE_NAME + "/" \
        + App::TERMINATION_STRING + "," \
        + " SignedHeaders=" + App::ACCEPT_HEADER + ";" \
        + App::CONTENT_HEADER + ";" \
        + App::HOST_HEADER + ";" \
        + App::XAMZDATE_HEADER + ";" \
        + App::XAMZTARGET_HEADER + "," \
        + " Signature=" + signatureString

    return authorizationValue
end


# Used to hash the payload and hash each previous step in the AWS signing process
#
# @param toHash - String to be hashed
# @return SHA256 hashed version of the input
def hashstr(message)
    sha256 = Digest::SHA256.new
    return (sha256.hexdigest message)
end


# Creates a printout of all information sent to the AGCOD service
#
# @param payload - The payload to be sent to the AGCOD service
# @param canonicalRequest - The entire canonical request calculated in Task 1
# @param canonicalRequestHash - SHA256 hash of canonical request
# @param stringToSign - The entire "String to Sign" calculated in Task 2
# @param authorizationValue - The entire authorization calculated in Task 3
# @param dateString - The short 8 digit format for an x-amz-date
# @param contentType - the wire format of content to be posted
def printRequestInfo(payload, canonicalRequest, canonicalRequestHash, stringToSign, authorizationValue, dateString, contentType)
    #Print everything to be sent:
    puts "\nPAYLOAD:"
    puts payload
    puts "\nHASHED PAYLOAD:"
    puts hashstr(payload)
    puts "\nCANONICAL REQUEST:"
    puts canonicalRequest
    puts "\nHASHED CANONICAL REQUEST:"
    puts canonicalRequestHash
    puts "\nSTRING TO SIGN:"
    puts stringToSign
    puts "\nDERIVED SIGNING KEY:"
    puts buildDerivedKey(dateString).unpack('H*').first
    puts "\nSIGNATURE:"

    #Check that the signature is moderately well formed to do string manipulation on
    if authorizationValue.index("Signature=") == nil or authorizationValue.index("Signature=") + 10 >= authorizationValue.length
        raise "Malformed Signature"
    end

    #Get the text from after the word "Signature=" to the end of the authorization signature
    puts authorizationValue[(authorizationValue.index("Signature=") + 10)..-1]
    puts "\nENDPOINT:"
    puts App::HOST
    puts "\nSIGNED REQUEST:"
    puts "POST " + App::REQUEST_URI + " HTTP/1.1"
    puts App::ACCEPT_HEADER + ":" + contentType
    puts App::CONTENT_HEADER + ":" + contentType
    puts App::HOST_HEADER + ":" + App::HOST
    puts App::XAMZDATE_HEADER + ":" + App::DATE_TIME_STRING
    puts App::XAMZTARGET_HEADER + ":" + App::SERVICE_TARGET
    puts App::AUTHORIZATION_HEADER + ":" + authorizationValue
    puts payload
end


# Creates the authentication signature used with AWS v4 and sets the appropriate properties within the connection
# based on the parameters used for AWS signing. Tasks described below can be found at
# http://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html
#
# @param conn - URL connection to host
# @param payload - The payload to be sent to the AGCOD service
# @param contentType - the wire format of content to be posted
def signRequestAWSv4(req, payload, contentType)
    if req == nil
        raise "ConnectException"
    end

    #Convert full date to x-amz-date by ignoring fields we don't need
    #dateString only needs digits for the year(4), month(2), and day(2).
    dateString =  App::DATE_TIME_STRING[0..7]

    #Set proper request properties for the connection, these correspond to what was used creating a canonical request
    #and the final Authorization
    req[App::ACCEPT_HEADER]     = contentType
    req[App::CONTENT_HEADER]    = contentType
    req[App::HOST_HEADER]       = App::HOST
    req[App::XAMZDATE_HEADER]   = App::DATE_TIME_STRING
    req[App::XAMZTARGET_HEADER] = App::SERVICE_TARGET

    #Begin Task 1: Creating a Canonical Request
    canonicalRequest = buildCanonicalRequest(payload, contentType)
    canonicalRequestHash = hashstr(canonicalRequest)

    #Begin Task 2: Creating a String to Sign
    stringToSign = buildStringToSign(canonicalRequestHash, dateString)

    #Begin Task 3: Creating a Signature
    authorizationValue = buildAuthSignature(stringToSign, dateString)

    #set final connection header
    req[App::AUTHORIZATION_HEADER] = authorizationValue

    #Print everything to be sent:
    printRequestInfo(payload, canonicalRequest, canonicalRequestHash, stringToSign, authorizationValue, dateString, contentType)
end

#Parse URL string to URI object
uri = URI.parse(App::HOST_NAME)

#Creates a new Net::HTTP object
conn = Net::HTTP.new(uri.host, uri.port)

#Turn on https flag for connection
conn.use_ssl = true

#Specify cryptographic protocol to reject non TLS1.2 connections
conn.ssl_version = :TLSv1_2
conn.verify_mode = OpenSSL::SSL::VERIFY_PEER

#Create POST request object
req = Net::HTTP::Post.new(uri.path)

#Set payload from user parameters
payload, contentType = setPayload()

#Inject payload into request
req.body = payload

#Calculate authentication signature in request
signRequestAWSv4(req, payload, contentType)

begin
    #Sends the HTTPRequest object "req" to the HTTP server.
    result = conn.request(req)

    puts "\nRESPONSE:"
    #Extract result from HTTPResponse object
    print result.body
 
rescue StandardError => e
    puts "\nERROR RESPONSE:"
    puts e
end
