require 'date'
require 'net/http'
require 'nokogiri'

module Rates

  def self.fetch(year = nil)
    year = year || Date.today.year

    # first we grab the 10 year treasury rates from yahoo (TNX)
    uri = URI("http://ichart.finance.yahoo.com/table.csv?s=%5ETNX&a=11&b=28&c=2011&d=11&e=31&f=#{year}&g=d&ignore=.csv")
    treasury = Net::HTTP.get_response(uri)
    raise treasury.message unless treasury.code == '200'

    # then we grab the Freddie Mac rates (PMMS)
    uri = URI("http://www.freddiemac.com/pmms/archive.html?year=#{year}")
    mortgage = Net::HTTP.get_response(uri)
    raise mortgage.message unless mortgage.code == '200'

    # parse the treasury rates
    rates = {}
    treasury.body.split.each do |line|
      fields = line.split(/,/)
      rates[fields[0]] = fields[4].to_f
    end

    # parse the mortgage rates and calculate the spread

    doc = Nokogiri::HTML(mortgage.body)
    dates = doc.css('h3').map { |node| Date.parse(node.text) }
    raise "Missing dates" if dates.empty?

    lines = []
    lines << "Date,30yr mortgage,10yr tbond,Spread"
    doc.css('table.table1').each_with_index do |node, i|
      node.css('tr').each do |node|
        if node.text =~ /Average Rates/
          rate = node.css('td')[0].text.to_f
          last = dates[i]
          first = last - 7
          values = []
          while (first < last) do
            values << rates[first.to_s] if rates[first.to_s]
            first += 1
          end
          average = values.inject(:+) / values.size
          lines << sprintf("%s,%.2f,%.2f,%.2f", last, rate, average, rate - average)
        end
      end
    end
    lines
  end

end
