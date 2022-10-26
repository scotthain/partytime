#!/usr/bin/env ruby
require 'aws-sdk-s3'
require 'csv'

# These should be in your .aws/credentials or something
Aws.config.update({
    credentials: Aws::Credentials.new('id key thing', 'passcode thing')
})

client = Aws::S3::Client.new(
    region: 'us-west-2',
)

# Some variables for ease of use
path = "dataz.csv"
bucket_name = "mah-bukkit"
target_directory = "/home/scott/code/scotthain/partytime/output/"

pp "Prepopulating a horrific array... ready GO"
accounts_or_something = Array.new
CSV.foreach(path) do |row|
    accounts_or_something.push(row[0])
end
pp "Horrific array loaded! GO TIME!"

pp "Ok here we go time to nom nom nom on that bukkit"
total_folders = 0
client.list_objects(bucket: bucket_name).each do |response|
    keys = response.contents.map(&:key)
    matches = Array.new
    keys.each do | key |
        accounts_or_something.select do |account|
            if key.start_with?(account)
                matches.push(key)
            end
        end
    end

    # so folders are really files in S3 because S3...
    # this means that 'mydir/i_hate_this' is a root object just like 'mydir/' they're just IDs
    matches.each do | not_really_a_folder |
        # make dir locally *sigh*
        if not_really_a_folder.end_with?('/') && !Dir.exist?(File.join(target_directory, not_really_a_folder))
            Dir.mkdir(File.join(target_directory, not_really_a_folder))
        end

        begin
        resp = client.get_object({
            bucket: bucket_name, 
            key: not_really_a_folder,
            response_target: target_directory + not_really_a_folder,
        })
        rescue Exception => exception
            # DO NOT DO THIS THIS IS BAD RUBBY
            if exception.class == Errno::EISDIR
                # skip it, we already created the directory
                pp "#{not_really_a_folder} -- Not a real error, we created the directory already."
                total_folders = total_folders + 1
            else
                pp "'#{not_really_a_folder}' -- #{exception}"
            end
        end
    end
    pp "Ok total folders processed: #{total_folders}"
    pp "This should match the number of things in the spreadsheet"
end
