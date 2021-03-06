class Signature < ActiveRecord::Base
  belongs_to :student

private

  def create_signature_request
    signature_request = HelloSign.create_embedded_signature_request(
      test_mode: ENV['HELLO_SIGN_TEST_MODE'],
      client_id: ENV['HELLO_SIGN_CLIENT_ID'],
      subject: @subject,
      signers: [
        {
          email_address: student.email,
          name: student.name
        }
      ],
      file_url: [@file]
    )
    self.signature_request_id = signature_request.data['signatures'].first['signature_id']
    self.sign_url = HelloSign.get_embedded_sign_url(signature_id: signature_request.signatures.first.data['signature_id']).sign_url
  end
end
