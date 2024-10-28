require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

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

def peak(dates, to_tally)
  tally = tally(dates, to_tally)
  max_reg_in_hour = tally.max_by(&:last)[1]
  tally.each do |hour, times|
    tally.delete(hour) unless times == max_reg_in_hour
  end
  tally.keys
end

def tally(dates, to_tally)
  hours = []
  dates.each do |date|
    hours << date.send(to_tally)
  end
  hours.tally
end

def print_peak(to_print, tally)
  print to_print

  tally.each do |data|
    print "#{data} "
  end
  puts ''
end

def format_hours(hours)
  hours.map! do |hour|
    Time.strptime(hour.to_s, '%H').strftime('%l%P').strip
  end
end

def format_days(days)
  days.map do |day|
    Date::DAYNAMES[day]
  end
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

    legislators = legislator_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
  end
end

peak_hours = peak(registration_dates, :hour)
peak_hours = format_hours(peak_hours)
print_peak('Peak hour/s: ', peak_hours)

peak_days = peak(registration_dates, :wday)
peak_days = format_days(peak_days)
print_peak('Peak day/s: ', peak_days)
