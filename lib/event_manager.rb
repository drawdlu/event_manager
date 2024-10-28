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
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
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
def create_time_obj(date_string)
  Time.strptime(date_string, '%m/%d/%y %H:%M')
end

def peak_hours(dates)
  tally = tally_hours(dates)
  max_reg_in_hour = tally.max_by(&:last)[1]
  tally.each do |hour, times|
    tally.delete(hour) unless times == max_reg_in_hour
  end
  print_peak(tally)
end

def tally_hours(dates)
  hours = []
  dates.each do |date|
    hours << date.hour
  end
  hours.tally
end

def print_peak(tally)
  peak_num = tally.length
  if peak_num > 1
    print 'Peak hours are '
  else
    print 'Peak hour is '
  end
  tally.each_key do |hour|
    formatted_hour = Time.strptime(hour.to_s, '%H').strftime('%l%P').strip
    print "#{formatted_hour} "
  end
  puts ''
end

puts 'Event Manager Initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

registration_dates = []

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

    registration_dates << create_time_obj(row[:regdate])

    # legislators = legislator_by_zipcode(zipcode)

    # form_letter = erb_template.result(binding)

    # save_thank_you_letter(id, form_letter)
  end
end

peak_hours(registration_dates)
