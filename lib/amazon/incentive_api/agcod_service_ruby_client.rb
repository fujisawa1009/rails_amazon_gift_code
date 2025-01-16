# Amazonインセンティブ APIの公式サンプルコード
# - AWS署名バージョン4の実装
# - リクエストの署名と認証
# - XMLおよびJSONペイロードの生成
# - HTTPSリクエストの実行
# - 以下のAPI操作をサポート:
#   - CreateGiftCard: ギフトカード作成
#   - CancelGiftCard: ギフトカードのキャンセル
#   - ActivateGiftCard: ギフトカードの有効化
#   - DeactivateGiftCard: ギフトカードの無効化
#   - ActivationStatusCheck: 有効化状態の確認
#   - GetGiftCardActivityPage: 活動履歴の取得[1]


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
  ActivateGiftCard        = 'ActivateGiftCard'.freeze
  DeactivateGiftCard      = 'DeactivateGiftCard'.freeze
  ActivationStatusCheck   = 'ActivationStatusCheck'.freeze
  CreateGiftCard          = 'CreateGiftCard'.freeze
  CancelGiftCard          = 'CancelGiftCard'.freeze
  GetGiftCardActivityPage = 'GetGiftCardActivityPage'.freeze
end

# An enumeration of supported formats for the payload
module PayloadType
  JSON                    = 'JSON'.freeze
  XML                     = 'XML'.freeze
end

module App
  # Static headers used in the request
  ACCEPT_HEADER = 'accept'.freeze
  CONTENT_HEADER = 'content-type'.freeze
  HOST_HEADER = 'host'.freeze
  XAMZDATE_HEADER = 'x-amz-date'.freeze
  XAMZTARGET_HEADER = 'x-amz-target'.freeze
  AUTHORIZATION_HEADER = 'Authorization'.freeze

  # Static format parameters
  DATE_FORMAT = '%Y%m%dT%H%M%SZ'.freeze

  # Signature calculation related parameters
  # HMAC_SHA256_ALGORITHM = "HmacSHA256"
  # HASH_SHA256_ALGORITHM = "SHA-256"
  AWS_SHA256_ALGORITHM = 'AWS4-HMAC-SHA256'.freeze
  KEY_QUALIFIER = 'AWS4'.freeze
  TERMINATION_STRING = 'aws4_request'.freeze

  # User and instance parameters
  AWS_KEY_ID = ''.freeze # Your KeyID
  AWS_SECRET_KEY = ''.freeze # Your Key
  DATE_TIME_STRING = Time.now.utc.strftime(DATE_FORMAT) # e.g. "20140630T224526Z"

  # Service and target (API) parameters
  REGION_NAME = 'us-east-1'.freeze # lowercase!  Ref http://docs.aws.amazon.com/general/latest/gr/rande.html
  SERVICE_NAME = 'AGCODService'.freeze

  # Payload parameters
  PARTNER_ID = ''.freeze
  REQUEST_ID = ''.freeze
  CARD_NUMBER = ''.freeze
  AMOUNT = 20
  CURRENCY_CODE = 'USD'.freeze

  # Additional payload parameters for CancelGiftCard
  GC_ID = ''.freeze

  # Additional payload parameters for GetGiftCardActivityPage
  PAGE_INDEX = 0
  PAGE_SIZE = 1
  UTC_START_DATE = ''.freeze # "yyyy-MM-ddTHH:mm:ss eg. 2013-06-01T23:10:10"
  UTC_END_DATE = ''.freeze # "yyyy-MM-ddTHH:mm:ss eg. 2013-06-01T23:15:10"
  SHOW_NOOPS = true

  # Parameters that specify what format the payload should be in and what fields will
  # be in the payload, based on the selected operation.
  MSG_PAYLOAD_TYPE = PayloadType::XML
  # MSG_PAYLOAD_TYPE = PayloadType::JSON
  SERVICE_OPERATION = AGCODServiceOperation::CreateGiftCard
  # SERVICE_OPERATION = AGCODServiceOperation::CancelGiftCard
  # SERVICE_OPERATION = AGCODServiceOperation::ActivateGiftCard
  # SERVICE_OPERATION = AGCODServiceOperation::DeactivateGiftCard
  # SERVICE_OPERATION = AGCODServiceOperation::ActivationStatusCheck
  # SERVICE_OPERATION = AGCODServiceOperation::GetGiftCardActivityPage

  # Parameters used in the message header
  HOST = 'agcod-v2-gamma.amazon.com'.freeze # Refer to the AGCOD tech spec for a list of end points based on region/environment
  PROTOCOL = 'https'.freeze
  QUERY_STRING = ''.freeze # empty
  REQUEST_URI = "/#{SERVICE_OPERATION}".freeze
  SERVICE_TARGET = "com.amazonaws.agcod.AGCODService.#{SERVICE_OPERATION}".freeze
  HOST_NAME = "#{PROTOCOL}://#{HOST}#{REQUEST_URI}".freeze
end

# Creates a dict containing the data to be used to form the request payload.
# @return the populated dict of data
def buildPayloadContent
  params = { partnerId: App::PARTNER_ID }
  if App::SERVICE_OPERATION == AGCODServiceOperation::ActivateGiftCard
    params['activationRequestId'] = App::REQUEST_ID
    params['cardNumber']   = App::CARD_NUMBER
    params['value']        = { 'currencyCode' => App::CURRENCY_CODE, 'amount' => App::AMOUNT }

  elsif App::SERVICE_OPERATION == AGCODServiceOperation::DeactivateGiftCard
    params['activationRequestId'] = App::REQUEST_ID
    params['cardNumber'] = App::CARD_NUMBER

  elsif App::SERVICE_OPERATION == AGCODServiceOperation::ActivationStatusCheck
    params['statusCheckRequestId'] = App::REQUEST_ID
    params['cardNumber'] = App::CARD_NUMBER

  elsif App::SERVICE_OPERATION == AGCODServiceOperation::CreateGiftCard
    params['creationRequestId'] = App::REQUEST_ID
    params['value'] = { 'currencyCode' => App::CURRENCY_CODE, 'amount' => App::AMOUNT }

  elsif App::SERVICE_OPERATION == AGCODServiceOperation::CancelGiftCard
    params['creationRequestId'] = App::REQUEST_ID
    params['gcId'] = App::GC_ID

  elsif App::SERVICE_OPERATION == AGCODServiceOperation::GetGiftCardActivityPage
    params['requestId'] = App::REQUEST_ID
    params['utcStartDate'] = App::UTC_START_DATE
    params['utcEndDate']   = App::UTC_END_DATE
    params['pageIndex']    = App::PAGE_INDEX
    params['pageSize']     = App::PAGE_SIZE
    params['showNoOps']    = App::SHOW_NOOPS

  else
    raise 'IllegalArgumentException'

  end

  request = "#{App::SERVICE_OPERATION}Request"
  { request => params }
end

# Sets the payload to be the requested encoding and creates the payload based on the static parameters.
# @return A tuple including the payload to be sent to the AGCOD service and the content type
def setPayload
  # Set payload based on operation and format
  payload_dict = buildPayloadContent
  if App::MSG_PAYLOAD_TYPE == PayloadType::XML
    contentType = 'charset=UTF-8'
    payload = Gyoku.xml(payload_dict)
  elsif App::MSG_PAYLOAD_TYPE == PayloadType::JSON
    contentType = 'application/json'
    # strip operation specifier from JSON payload
    operation_content_dict = payload_dict[payload_dict.keys.first]
    payload = JSON.dump(operation_content_dict)
  else
    raise 'IllegalPayloadType'
  end
  [payload, contentType]
end

# Creates a canonical request based on set static parameters
# http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
#
# @param payload - The payload to be sent to the AGCOD service
# @param contentType - the wire format of content to be posted
# @return The whole canonical request string to be used in Task 2
def buildCanonicalRequest(payload, contentType)
  # Create a SHA256 hash of the payload, used in authentication
  payloadHash = hashstr(payload)

  # Canonical request headers should be sorted by lower case character code
  "POST\n#{App::REQUEST_URI}\n#{App::QUERY_STRING}\n#{App::ACCEPT_HEADER}:#{contentType}\n#{App::CONTENT_HEADER}:#{contentType}\n#{App::HOST_HEADER}:#{App::HOST}\n#{App::XAMZDATE_HEADER}:#{App::DATE_TIME_STRING}\n#{App::XAMZTARGET_HEADER}:#{App::SERVICE_TARGET}\n\n#{App::ACCEPT_HEADER};#{App::CONTENT_HEADER};#{App::HOST_HEADER};#{App::XAMZDATE_HEADER};#{App::XAMZTARGET_HEADER}\n#{payloadHash}"
end

# Uses the previously calculated canonical request to create a single "String to Sign" for the request
# http://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
#
# @param canonicalRequestHash - SHA256 hash of the canonical request
# @param dateString - The short 8 digit format for an x-amz-date
# @return The "String to Sign" used in Task 3
def buildStringToSign(canonicalRequestHash, dateString)
  "#{App::AWS_SHA256_ALGORITHM}\n#{App::DATE_TIME_STRING}\n#{dateString}/#{App::REGION_NAME}/#{App::SERVICE_NAME}/#{App::TERMINATION_STRING}\n#{canonicalRequestHash}"
end

# Create a series of Hash-based Message Authentication Codes for use in the final signature
#
# @param data - String to be Hashed
# @param bkey - Key used in signing
# @return Byte string of resultant hash
def hmac_binary(data, bkey)
  OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), bkey, data)
end

# This function uses given parameters to create a derived key based on the secret key and parameters related to the call
# http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
#
# @param dateString - The short 8 digit format for an x-amz-date
# @return The derived key used in creating the final signature
def buildDerivedKey(dateString)
  signatureAWSKey = App::KEY_QUALIFIER + App::AWS_SECRET_KEY

  # Calculate the derived key from given values
  hmac_binary(App::TERMINATION_STRING,
              hmac_binary(App::SERVICE_NAME,
                          hmac_binary(App::REGION_NAME,
                                      hmac_binary(dateString, signatureAWSKey))))
end

# Calculates the signature to put in the POST message header 'Authorization'
# http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
#
# @param stringToSign - The entire "String to Sign" calculated in Task 2
# @param dateString - The short 8 digit format for an x-amz-date
# @return The whole field to be used in the Authorization header for the message
def buildAuthSignature(stringToSign, dateString)
  # Use derived key and "String to Sign" to make the final signature
  derivedKey = buildDerivedKey(dateString)

  finalSignature = hmac_binary(stringToSign, derivedKey)

  signatureString = finalSignature.unpack1('H*')
  "#{App::AWS_SHA256_ALGORITHM} Credential=#{App::AWS_KEY_ID}/#{dateString}/#{App::REGION_NAME}/#{App::SERVICE_NAME}/#{App::TERMINATION_STRING}, SignedHeaders=#{App::ACCEPT_HEADER};#{App::CONTENT_HEADER};#{App::HOST_HEADER};#{App::XAMZDATE_HEADER};#{App::XAMZTARGET_HEADER}, Signature=#{signatureString}"
end

# Used to hash the payload and hash each previous step in the AWS signing process
#
# @param toHash - String to be hashed
# @return SHA256 hashed version of the input
def hashstr(message)
  sha256 = Digest::SHA256.new
  (sha256.hexdigest message)
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
def printRequestInfo(payload, canonicalRequest, canonicalRequestHash, stringToSign, authorizationValue, dateString,
                     contentType)
  # Print everything to be sent:
  Rails.logger.debug "\nPAYLOAD:"
  Rails.logger.debug payload
  Rails.logger.debug "\nHASHED PAYLOAD:"
  Rails.logger.debug hashstr(payload)
  Rails.logger.debug "\nCANONICAL REQUEST:"
  Rails.logger.debug canonicalRequest
  Rails.logger.debug "\nHASHED CANONICAL REQUEST:"
  Rails.logger.debug canonicalRequestHash
  Rails.logger.debug "\nSTRING TO SIGN:"
  Rails.logger.debug stringToSign
  Rails.logger.debug "\nDERIVED SIGNING KEY:"
  Rails.logger.debug buildDerivedKey(dateString).unpack1('H*')
  Rails.logger.debug "\nSIGNATURE:"

  # Check that the signature is moderately well formed to do string manipulation on
  if authorizationValue.index('Signature=').nil? || (authorizationValue.index('Signature=') + 10 >= authorizationValue.length)
    raise 'Malformed Signature'
  end

  # Get the text from after the word "Signature=" to the end of the authorization signature
  Rails.logger.debug authorizationValue[(authorizationValue.index('Signature=') + 10)..]
  Rails.logger.debug "\nENDPOINT:"
  Rails.logger.debug App::HOST
  Rails.logger.debug "\nSIGNED REQUEST:"
  Rails.logger.debug { "POST #{App::REQUEST_URI} HTTP/1.1" }
  Rails.logger.debug { "#{App::ACCEPT_HEADER}:#{contentType}" }
  Rails.logger.debug { "#{App::CONTENT_HEADER}:#{contentType}" }
  Rails.logger.debug { "#{App::HOST_HEADER}:#{App::HOST}" }
  Rails.logger.debug { "#{App::XAMZDATE_HEADER}:#{App::DATE_TIME_STRING}" }
  Rails.logger.debug { "#{App::XAMZTARGET_HEADER}:#{App::SERVICE_TARGET}" }
  Rails.logger.debug { "#{App::AUTHORIZATION_HEADER}:#{authorizationValue}" }
  Rails.logger.debug payload
end

# Creates the authentication signature used with AWS v4 and sets the appropriate properties within the connection
# based on the parameters used for AWS signing. Tasks described below can be found at
# http://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html
#
# @param conn - URL connection to host
# @param payload - The payload to be sent to the AGCOD service
# @param contentType - the wire format of content to be posted
def signRequestAWSv4(req, payload, contentType)
  raise 'ConnectException' if req.nil?

  # Convert full date to x-amz-date by ignoring fields we don't need
  # dateString only needs digits for the year(4), month(2), and day(2).
  dateString = App::DATE_TIME_STRING[0..7]

  # Set proper request properties for the connection, these correspond to what was used creating a canonical request
  # and the final Authorization
  req[App::ACCEPT_HEADER]     = contentType
  req[App::CONTENT_HEADER]    = contentType
  req[App::HOST_HEADER]       = App::HOST
  req[App::XAMZDATE_HEADER]   = App::DATE_TIME_STRING
  req[App::XAMZTARGET_HEADER] = App::SERVICE_TARGET

  # Begin Task 1: Creating a Canonical Request
  canonicalRequest = buildCanonicalRequest(payload, contentType)
  canonicalRequestHash = hashstr(canonicalRequest)

  # Begin Task 2: Creating a String to Sign
  stringToSign = buildStringToSign(canonicalRequestHash, dateString)

  # Begin Task 3: Creating a Signature
  authorizationValue = buildAuthSignature(stringToSign, dateString)

  # set final connection header
  req[App::AUTHORIZATION_HEADER] = authorizationValue

  # Print everything to be sent:
  printRequestInfo(payload, canonicalRequest, canonicalRequestHash, stringToSign, authorizationValue, dateString,
                   contentType)
end

# Parse URL string to URI object
uri = URI.parse(App::HOST_NAME)

# Creates a new Net::HTTP object
conn = Net::HTTP.new(uri.host, uri.port)

# Turn on https flag for connection
conn.use_ssl = true

# Specify cryptographic protocol to reject non TLS1.2 connections
conn.ssl_version = :TLSv1_2
conn.verify_mode = OpenSSL::SSL::VERIFY_PEER

# Create POST request object
req = Net::HTTP::Post.new(uri.path)

# Set payload from user parameters
payload, contentType = setPayload

# Inject payload into request
req.body = payload

# Calculate authentication signature in request
signRequestAWSv4(req, payload, contentType)

begin
  # Sends the HTTPRequest object "req" to the HTTP server.
  result = conn.request(req)

  Rails.logger.debug "\nRESPONSE:"
  # Extract result from HTTPResponse object
  Rails.logger.debug result.body
rescue StandardError => e
  Rails.logger.debug "\nERROR RESPONSE:"
  Rails.logger.debug e
end
