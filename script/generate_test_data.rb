require 'csv'
require 'write_xlsx'

output_csv = 'test_data_bulk_large.csv'
output_excel = 'test_data_bulk_large.xlsx'

modes = %w[UPI CARD NETBANKING]
rows = 1200

def random_time
  Time.at(Time.now.to_i - rand(0..30*24*60*60))
end

puts "Generating #{rows} rows of test data..."

CSV.open(output_csv, 'wb') do |csv|
  csv << %w[amount mode created_at]

  rows.times do |i|
    # Introduce outliers every 100 rows
    if i % 100 == 0
      amount = rand(1000000.0..5000000.0).round(2) # Outlier amount
      time = Time.now.strftime("%Y-%m-%d 03:00:00") # Outlier time (early morning)
    else
      amount = rand(10.0..5000.0).round(2)
      time = random_time.strftime("%Y-%m-%d %H:%M:%S")
    end

    csv << [ amount, modes.sample, time ]
  end
end

puts "CSV generated: #{output_csv}"

workbook = WriteXLSX.new(output_excel)
worksheet = workbook.add_worksheet

worksheet.write(0, 0, 'amount')
worksheet.write(0, 1, 'mode')
worksheet.write(0, 2, 'created_at')

rows.times do |i|
  row = i + 1
  if i % 100 == 0
    amount = rand(1000000.0..5000000.0).round(2)
    time = Time.now.strftime("%Y-%m-%d 03:00:00")
  else
    amount = rand(10.0..5000.0).round(2)
    time = random_time.strftime("%Y-%m-%d %H:%M:%S")
  end

  worksheet.write(row, 0, amount)
  worksheet.write(row, 1, modes.sample)
  worksheet.write(row, 2, time)
end

workbook.close
puts "Excel generated: #{output_excel}"
