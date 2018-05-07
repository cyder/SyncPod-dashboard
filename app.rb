require 'sinatra/base'
require 'mysql2'
require 'json'
require 'date'
require 'pp'

require 'dotenv/load'

def date2js d
  return "Date(#{[d.year, d.month - 1, d.day].join(',')})"
end

class App < Sinatra::Base
  get '/' do
    send_file File.join(settings.public_folder, 'index.html')
  end
  
  get '/api/v1/status/room' do
    content_type :json
    
    db = Mysql2::Client.new(
      database: 'YouTube_Sync_production',
      host:     ENV['SYNCPOD_DB_HOST'],
      username: ENV['SYNCPOD_DB_USERNAME'],
      password: ENV['SYNCPOD_DB_PASSWORD'],
    )
    
    sql =<<~SQL
      SELECT
        DATE_FORMAT(entry_at, "%Y-%m-%d") as `date`,
        COUNT(DISTINCT user_id) as `count`
      FROM YouTube_Sync_production.user_room_logs
      WHERE created_at >= '2018-01-01'
      GROUP BY date
      ORDER BY date
    SQL
    
    data = db.query(sql).map{|r| {date: Date.parse(r['date']), count: r['count']} }.sort_by{|e| e[:date]}
    start_at = data.first[:date]
    
    result = data.inject([]) do |before, v|
      if before.last && (b = before.last[:date])
        # if missed point found
        if v[:date] - b > 1
          (v[:date] - b - 1).to_i.times do |x|
            before << {
              date: (b + x + 1),
              count: 0,
            }
          end
        end
      end
      before << v
    end
    
    {
      cols: [
        {
          label: 'Date',
          type: 'date',
        },
        {
          label: 'Users',
          type: 'number',
        },
      ],
      rows: result.map{|r|
        {
          c: [
            { v: date2js(r[:date]) },
            { v: r[:count] },
          ]
        }
      }
    }.to_json
  end
  
  get '/api/v1/status/chat' do
    content_type :json
    
    db = Mysql2::Client.new(
      database: 'YouTube_Sync_production',
      host:     ENV['SYNCPOD_DB_HOST'],
      username: ENV['SYNCPOD_DB_USERNAME'],
      password: ENV['SYNCPOD_DB_PASSWORD'],
    )
    
    sql =<<~SQL
      SELECT
        DATE_FORMAT(created_at, "%Y-%m-%d") as `date`,
        COUNT(DISTINCT id) as `count`
      FROM YouTube_Sync_production.chats
      WHERE created_at >= '2018-01-01'
        AND chat_type = 'user'
      GROUP BY date
      ORDER BY date
    SQL
    
    data = db.query(sql).map{|r| {date: Date.parse(r['date']), count: r['count']} }.sort_by{|e| e[:date]}
    start_at = data.first[:date]
    
    result = data.inject([]) do |before, v|
      if before.last && (b = before.last[:date])
        # if missed point found
        if v[:date] - b > 1
          (v[:date] - b - 1).to_i.times do |x|
            before << {
              date: (b + x + 1),
              count: 0,
            }
          end
        end
      end
      before << v
    end
    
    {
      cols: [
        {
          label: 'Date',
          type: 'date',
        },
        {
          label: 'Messages',
          type: 'number',
        },
      ],
      rows: result.map{|r|
        {
          c: [
            { v: date2js(r[:date]) },
            { v: r[:count] },
          ]
        }
      }
    }.to_json
  end
end

App.run!
