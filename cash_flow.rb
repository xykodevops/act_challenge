#!/usr/bin/env ruby
#coding: utf-8

require 'sinatra'
require 'yaml/store'
require 'yaml'

set :bind, '0.0.0.0'
set :port, 8080

Transaction_Type = {
  'D' => 'Debit',
  'C' => 'Credit',
}

class Transaction
  attr_accessor :amount, :date, :description
  
  def initialize(amount, date, description)
    @amount = amount
    @date = date
    @description = description
  end
end

class Debit < Transaction
end

class Credit < Transaction
end

get '/' do
  erb :index
end

store = YAML::Store.new('transactions.yml')

post '/cashflow' do

  amount = params['amount']
  description = params['description']
  type = params['type']
  date = params['date']

  # Armazena a transação no arquivo YAML
  store.transaction do
    store['transactions'] ||= []
    store['transactions'] << {
      amount: amount,
      description: description,
      type: type,
      date: date
    }
  end

  # Redireciona para a página inicial
  redirect '/'
end


get '/summary' do
  data = YAML.load_file('transactions.yml')
  transactions = data['transactions']

  summary = {}
  transactions.each do |t|
    date = DateTime.parse(t[:date]).strftime('%Y-%m-%d')
    if summary[date].nil?
      summary[date] = { credit: 0, debit: 0 }
    end
    if t[:type] == 'C'
      summary[date][:credit] += t[:amount].to_i
    else
      summary[date][:debit] += t[:amount].to_i
    end
  end

  erb :summary, locals: { summary: summary }
end

get '/summary/:date' do
  @transactions = YAML.load_file('transactions.yml')['transactions'].select { |t| t[:date] == params[:date] }
  erb :day_summary
end
