module Healthcheck
  class S3
    def name
      :s3
    end

    def status
      connection = Fog::AWS::Storage.new(
        { use_iam_profile: true, region: ENV["AWS_REGION"] }
      )

      connection.directories.get("non-existant-bucket")

      GovukHealthcheck::OK
    rescue StandardError
      GovukHealthcheck::CRITICAL
    end
  end
end
