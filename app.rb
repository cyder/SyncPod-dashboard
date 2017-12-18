require 'sinatra/base'
require 'mysql2'
require 'json'
require 'pp'

require 'dotenv/load'

def date2js str
  y, m, d = str.split('-').map(&:to_i)
  m -= 1
  return "Date(#{[y, m, d].join(',')})"
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
      GROUP BY date
      ORDER BY date
    SQL
    
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
      rows: db.query(sql).map{|r|
        {
          c: [
            { v: date2js(r['date']) },
            { v: r['count'] },
          ]
        }
      }
    }.to_json
  end
end

App.run!
