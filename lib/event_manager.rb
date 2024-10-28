require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislator_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('secret.key').strip

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representative by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def format_number(number)
  number.insert(3, '-').insert(7, '-')
end

def clean_number(number)
  number = number.scan(/\d/).join

  if number.length == 10
    format_number(number)
  elsif number.length == 11 && number[0] == 1
    format_number(number[1..10])
  else
    nil
  end
end

# creates date object assuming that the format of string is
# 'month/day/year hour:minute'
# assume that year only has 2 digits with no century
def create_date_obj(date_string)
  date_time = date_string.split(' ')
  date = date_time[0].split('/')
  time = date_time[1].split(':')
  Time.new(date[2].rjust(4, '20'), date[0], date[1], time[0], time[1])
end

puts 'Event Manager Initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

if File.exist? 'event_attendees.csv'
  contents = CSV.open(
    'event_attendees.csv', 
    headers: true, 
    header_converters: :symbol
    )
  contents.each do |row|
    id = row[0]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    phone = row[:homephone]

    num = clean_number(phone)

    date_time = create_date_obj(row[:regdate])

    # legislators = legislator_by_zipcode(zipcode)

    # form_letter = erb_template.result(binding)
    
    # save_thank_you_letter(id, form_letter)

  end
end
