class Provider::AlphaVantage < Provider
  include SecurityConcept

  Error = Class.new(Provider::Error)

  BASE_URL = "https://www.alphavantage.co/query"

  REGION_TO_COUNTRY_CODE = {
    "United States" => "US",
    "United Kingdom" => "GB",
    "Canada" => "CA",
    "Germany" => "DE",
    "France" => "FR",
    "Japan" => "JP",
    "China" => "CN",
    "Australia" => "AU",
    "India" => "IN",
    "Brazil" => "BR"
  }.freeze

  def initialize(api_key)
    @api_key = api_key
  end

  def search_securities(symbol, country_code: nil, exchange_operating_mic: nil)
    with_provider_response do
      parsed = get("SYMBOL_SEARCH", keywords: symbol)

      parsed.fetch("bestMatches", []).map do |match|
        Security.new(
          symbol: match["1. symbol"],
          name: match["2. name"],
          logo_url: nil,
          exchange_operating_mic: nil,
          country_code: REGION_TO_COUNTRY_CODE[match["4. region"]]
        )
      end
    end
  end

  def fetch_security_info(symbol:, exchange_operating_mic:)
    with_provider_response do
      parsed = get("OVERVIEW", symbol: symbol)

      raise Error, "No data returned for symbol #{symbol}" if parsed.empty?

      SecurityInfo.new(
        symbol: symbol,
        name: parsed["Name"],
        links: { "official_site" => parsed["OfficialSite"] }.compact_blank,
        logo_url: nil,
        description: parsed["Description"],
        kind: parsed["AssetType"],
        exchange_operating_mic: exchange_operating_mic
      )
    end
  end

  def fetch_security_price(symbol:, exchange_operating_mic: nil, date:)
    with_provider_response do
      prices = fetch_daily_time_series(symbol)
      price_data = prices[date.to_s]

      raise Error, "No price found for #{symbol} on #{date}" unless price_data

      Price.new(
        symbol: symbol,
        date: date.to_date,
        price: price_data["4. close"].to_d,
        currency: "USD",
        exchange_operating_mic: exchange_operating_mic
      )
    end
  end

  def fetch_security_prices(symbol:, exchange_operating_mic: nil, start_date:, end_date:)
    with_provider_response do
      prices = fetch_daily_time_series(symbol)
      start_date = start_date.to_date
      end_date = end_date.to_date

      prices
        .filter_map do |date_str, price_data|
          date = Date.parse(date_str)
          next unless (start_date..end_date).cover?(date)

          Price.new(
            symbol: symbol,
            date: date,
            price: price_data["4. close"].to_d,
            currency: "USD",
            exchange_operating_mic: exchange_operating_mic
          )
        end
        .sort_by(&:date)
    end
  end

  private
    attr_reader :api_key

    def get(function, params = {})
      response = client.get(BASE_URL, params.merge(function: function, apikey: api_key))
      parsed = JSON.parse(response.body)

      if parsed.key?("Note") || parsed.key?("Information")
        raise Error, "Alpha Vantage rate limit exceeded — consider upgrading your API plan"
      end

      parsed
    end

    def fetch_daily_time_series(symbol)
      parsed = get("TIME_SERIES_DAILY", symbol: symbol, outputsize: "full")

      raise Error, "No price data returned for symbol #{symbol}" unless parsed.key?("Time Series (Daily)")

      parsed["Time Series (Daily)"]
    end

    def client
      @client ||= Faraday.new do |faraday|
        faraday.request(:retry, max: 2, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2)
        faraday.response :raise_error
      end
    end
end
