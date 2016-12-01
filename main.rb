require "json"
require 'rest-client'
require 'sinatra'
require 'bing-search'
require 'faraday'
require 'line/bot'
require 'date'
require 'net/https'
require 'yaml'
require 'cgi'
require 'net/http'

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  genre =["居酒屋","ダイニングバー","創作料理","和食","洋食","イタリアンフレンチ","中華","焼肉・韓国料理","アジアン","各国料理","カラオケパーティ","バー・カクテル","ラーメン","お好み焼き・もんじゃ・鉄板","カフェ・スイーツ"]
  genreid = ["G001","G002","G003","G004","G005","G006","G007","G008","G009","G010","G011","G012","G013","G016","G014"]
  price_id = ["B001","B002","B003","B008","B004","B005","B006"]
  price_name =["2000以内","2000~3000","3000~4000","4000~5000","5000~7000","7000~10000","10000~"]

 events.each { |event|
    case event
    when Line::Bot::Event::Postback

      puts event['postback']['data']
      pat = event['postback']['data']
    if event['postback']['data'] =~ /case01/
      strary = event['postback']['data'].split(",")
      pass_lat = strary[1]
      pass_long = strary[2]
      message = genre_sender(*genre,*genreid,pass_lat,pass_long)
      client.reply_message(event['replyToken'], message)
        elsif event['postback']['data'].include?("G") && !event['postback']['data'].include?("B")
      strary = event['postback']['data'].split(",")
      pass_genre = strary[0]
      pass_lat = strary[1]
      pass_lon = strary[2]
      message = price_sender(*price_name,*price_id,pass_genre,pass_lat,pass_lon)
      client.reply_message(event['replyToken'], message)
    elsif event['postback']['data'].include?("B") && event['postback']['data'].include?("G")
      strary = event['postback']['data'].split(",")
      pass_budget = strary[0]
      pass_genre = strary[1]
      pass_lat = strary[2]
      pass_long = strary[3]
      message = grnavi_search(pass_lat,pass_long,pass_genre,pass_budget)
      client.reply_message(event['replyToken'], message)
      end
    when Line::Bot::Event::MessageType::Location
      latitude = event.message['latitude']
      longitude = event.message['longitude']
      message = button_sender("飲食店","雨雲","その他","case01,#{latitude},#{longitude}","case02,#{latitude},#{longitude}","case03,#{latitude},#{longitude}")
      client.reply_message(event['replyToken'], message)
          # message  = image_sender(img)
        # message = text_sender(text)
        client.reply_message(event['replyToken'], message)
      end
       }

  "OK"
end
def grnavi_search(latitude,longitude,genre,budget)
  conn = Faraday::Connection.new(url: 'http://webservice.recruit.co.jp/hotpepper/gourmet/v1/') do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
    response = conn.get do |req|
              req.params[:key] = ENV["hot_key"]

              req.params[:lat] = latitude.to_f
              req.params[:lng] = longitude.to_f
              req.params[:genre] = genre
              req.params[:budget] = budget
              req.params[:range] = 1
              req.params[:count] = 100
              req.params[:format] = 'json'
              req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end
     json = JSON.parse(response.body)
    if (json['results']['shop']).count < 5
      cone1 = conn.get do |req|
       req.params[:key] = ENV["hot_key"]

              req.params[:lat] = latitude.to_f
              req.params[:lng] = longitude.to_f
              req.params[:genre] = genre
              req.params[:budget] = budget
              req.params[:range] = 2
              req.params[:count] = 100
              req.params[:format] = 'json'
              req.headers['Content-Type'] = 'application/json; charset=UTF-8'
        end
        conjson1 = JSON.parse(cone1.body)
              if (conjson1['results']['shop']).count < 5
                    cone2 = conn.get do |req|
                      req.params[:key] = ENV["hot_key"]
                      req.params[:lat] = latitude.to_f
                      req.params[:lng] = longitude.to_f
                      req.params[:genre] = genre
                      req.params[:budget] = budget
                      req.params[:range] = 3
                      req.params[:count] = 100
                      req.params[:format] = 'json'
                      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
                      end
                  conjson2 = JSON.parse(cone2.body)
                    if (conjson2['results']['shop'].count) < 5
                        cone3 = conn.get do |req|
                          req.params[:key] = ENV["hot_key"]
                          req.params[:lat] = latitude.to_f
                          req.params[:lng] = longitude.to_f
                          req.params[:genre] = genre
                          req.params[:budget] = budget
                          req.params[:range] = 4
                          req.params[:count] = 100
                          req.params[:format] = 'json'
                          req.headers['Content-Type'] = 'application/json; charset=UTF-8'
                          end
                      conjson3 = JSON.parse(cone3.body)
                        if(conjson3['results']['shop']).count < 5
                             cone4 = conn.get do |req|
                          req.params[:key] = ENV["hot_key"]
                          req.params[:lat] = latitude.to_f
                          req.params[:lng] = longitude.to_f
                          req.params[:genre] = genre
                          req.params[:budget] = budget
                          req.params[:range] = 5
                          req.params[:count] = 100
                          req.params[:format] = 'json'
                          req.headers['Content-Type'] = 'application/json; charset=UTF-8'
                          end
                          conjson4 = JSON.parse(cone4.body)
                            img = Array.new
                            title  = Array.new
                            text = Array.new
                            shop_url = Array.new
                              for o in 0..4 do
                              img[o] = conjson4['results']['shop'][o]['photo']['pc']['l']
                              title[o] = conjson4['results']['shop'][o]['name']
                              text[o] = conjson4['results']['shop'][o]['catch']
                              shop_url[o] = conjson4['results']['shop'][o]['urls']['pc']
                              end
                        else

                            img = Array.new
                            title  = Array.new
                            text = Array.new
                            shop_url = Array.new
                              for o in 0..4 do
                              img[o] = conjson3['results']['shop'][o]['photo']['pc']['l']
                              title[o] = conjson3['results']['shop'][o]['name']
                              text[o] = conjson3['results']['shop'][o]['catch']
                              shop_url[o] = conjson3['results']['shop'][o]['urls']['pc']
                              end
                        end
                    else
                       img = Array.new
                            title  = Array.new
                            text = Array.new
                            shop_url = Array.new
                              for o in 0..4 do
                              img[o] = conjson2['results']['shop'][o]['photo']['pc']['l']
                              title[o] = conjson2['results']['shop'][o]['name']
                              text[o] = conjson2['results']['shop'][o]['catch']
                              shop_url[o] = conjson2['results']['shop'][o]['urls']['pc']
                              end
                    end
            else
               img = Array.new
                            title  = Array.new
                            text = Array.new
                            shop_url = Array.new
                              for o in 0..4 do
                              img[o] = conjson1['results']['shop'][o]['photo']['pc']['l']
                              title[o] = conjson1['results']['shop'][o]['name']
                              text[o] = conjson1['results']['shop'][o]['catch']
                              shop_url[o] = conjson1['results']['shop'][o]['urls']['pc']
                              end
            end
    else
       img = Array.new
                            title  = Array.new
                            text = Array.new
                            shop_url = Array.new
                              for o in 0..4 do
                              img[o] = json['results']['shop'][o]['photo']['pc']['l']
                              title[o] = json['results']['shop'][o]['name']
                              text[o] = json['results']['shop'][o]['catch']
                              shop_url[o] = json['results']['shop'][o]['urls']['pc']
                              end
     end

    return cursel_sender(*img,*title,*text,*shop_url)
end
def cursel_sender(img1,img2,img3,img4,img5,title1,title2,title3,title4,title5,text1,text2,text3,text4,text5,shop_url1,shop_url2,shop_url3,shop_url4,shop_url5)
message = {
  "type": "template",
  "altText": "this is a carousel template",
  "template": {
      "type": "carousel",
      "columns": [
         {
            "thumbnailImageUrl": img1,
            "title": title1[0,39],
            "text": text1[0,59],
            "actions": [
                {
                    "type": "postback",
                    "label": "Buy",
                    "data": "action=buy&itemid=111"
                },
                {
                    "type": "postback",
                    "label": "Add to cart",
                    "data": "action=add&itemid=111"
                },
                {
                    "type": "uri",
                    "label": "View detail",
                    "uri": shop_url1
                }
            ]
          },
          {
            "thumbnailImageUrl": img2,
            "title": title2[0,39],
            "text": text2[0,59],
            "actions": [
                {
                    "type": "postback",
                    "label": "Buy",
                    "data": "action=buy&itemid=111"
                },
                {
                    "type": "postback",
                    "label": "Add to cart",
                    "data": "action=add&itemid=111"
                },
                {
                    "type": "uri",
                    "label": "View detail",
                    "uri": shop_url2
                }
            ]
          },
          {
            "thumbnailImageUrl": img3,
            "title": title3[0,39],
            "text": text3[0,59],
            "actions": [
                {
                    "type": "postback",
                    "label": "Buy",
                    "data": "action=buy&itemid=222"
                },
                {
                    "type": "postback",
                    "label": "Add to cart",
                    "data": "action=add&itemid=222"
                },
                {
                    "type": "uri",
                    "label": "View detail",
                    "uri": shop_url3
                }
            ]
          },
          {
            "thumbnailImageUrl": img4,
            "title": title4[0,39],
            "text": text4[0,59],
            "actions": [
                {
                    "type": "postback",
                    "label": "Buy",
                    "data": "action=buy&itemid=222"
                },
                {
                    "type": "postback",
                    "label": "Add to cart",
                    "data": "action=add&itemid=222"
                },
                {
                    "type": "uri",
                    "label": "View detail",
                    "uri": shop_url4
                }
            ]
          },
          {
            "thumbnailImageUrl": img5,
            "title":title5[0,39],
            "text": text5[0,59],
            "actions": [
                {
                    "type": "postback",
                    "label": "Buy",
                    "data": "action=buy&itemid=222"
                },
                {
                    "type": "postback",
                    "label": "Add to cart",
                    "data": "action=add&itemid=222"
                },
                {
                    "type": "uri",
                    "label": "View detail",
                    "uri": shop_url5
                }
            ]
          }
                ]
  }
}
end

def button_sender(text1,text2,text3,br1,br2,br3)
message = {
  "type": "template",
  "altText": "this is a buttons template",
  "template": {
      "type": "buttons",
      "text": "ご用はなんですか？",
      "actions": [
          {
            "type": "postback",
            "label": text1,
            "data": br1
          },
          {
            "type": "postback",
            "label": text2,
             "data": br2
          },
          {
            "type": "postback",
            "label": text3,
             "data": br3
          }
      ]
  }
}

end

def price_sender(text1,text2,text3,text4,text5,text6,text7,br1,br2,br3,br4,br5,br6,br7,addx,lat,lon)
message = {
  "type": "template",
  "altText": "this is a carousel template",
  "template": {
      "type": "carousel",
      "columns": [{
           "text": "ジャンル",
            "actions": [
          {
            "type": "postback",
            "label": text1,
            "data": "#{br1},#{addx},#{lat},#{lon}"
          },
          {
            "type": "postback",
            "label": text2,
             "data": "#{br2},#{addx},#{lat},#{lon}"
          },
          {
            "type": "postback",
            "label": text3,
             "data": "#{br3},#{addx},#{lat},#{lon}"
          }
      ]
          },
          {
            "text": "ジャンル",
            "actions": [
          {
            "type": "postback",
            "label": text4,
            "data": "#{br4},#{addx},#{lat},#{lon}"
          },
          {
            "type": "postback",
            "label": text5,
             "data": "#{br5},#{addx},#{lat},#{lon}"
          },
          {
            "type": "postback",
            "label": text6,
             "data": "#{br6},#{addx},#{lat},#{lon}"
          }
      ]
          },
      ]
  }
}
end
def genre_sender(text1,text2,text3,text4,text5,text6,text7,text8,text9,text10,text11,text12,text13,text14,text15,br1,br2,br3,br4,br5,br6,br7,br8,br9,br10,br11,br12,br13,br14,br15,x,y)
message = {
  "type": "template",
  "altText": "this is a carousel template",
  "template": {
      "type": "carousel",
      "columns": [{
           "text": "ジャンル",
            "actions": [
          {
            "type": "postback",
            "label": text1,
            "data": "#{br1},#{x},#{y}"
          },
          {
            "type": "postback",
            "label": text2,
             "data": "#{br2},#{x},#{y}"
          },
          {
            "type": "postback",
            "label": text3,
             "data": "#{br3},#{x},#{y}"
          }
      ]
          },
          {
            "text": "ジャンル",
            "actions": [
          {
            "type": "postback",
            "label": text4,
            "data": "#{br4},#{x},#{y}"
          },
          {
            "type": "postback",
            "label": text5,
             "data": "#{br5},#{x},#{y}"
          },
          {
            "type": "postback",
            "label": text6,
             "data": "#{br6},#{x},#{y}"
          }
      ]
          },
          {
            "text": "ジャンル",
            "actions": [
          {
            "type": "postback",
            "label": text7,
            "data": "#{br7},#{x},#{y}"
          },
          {
            "type": "postback",
            "label": text8,
             "data": "#{br8},#{x},#{y}"
          },
          {
            "type": "postback",
            "label": text9,
             "data": "#{br9},#{x},#{y}"
          }
      ]
          },
                    {
            "text": "ジャンル",
            "actions": [
          {
            "type": "postback",
            "label": text10,
            "data": "#{br10},#{x},#{y}"
          },
          {
            "type": "postback",
            "label": text11,
             "data": "#{br11},#{x},#{y}"
          },
          {
            "type": "postback",
            "label": text9,
             "data": "#{br12},#{x},#{y}"
          }
      ]
          },
          {
            "text": "ジャンル",
            "actions": [
          {
            "type": "postback",
            "label": text13,
            "data": "#{br13},#{x},#{y}"
          },
          {
            "type": "postback",
            "label": text14,
            "data": "#{br14},#{x},#{y}"
          },
          {
            "type": "postback",
            "label": text15,
             "data": "#{br15},#{x},#{y}"
          }
      ]
          }
      ]
  }
}
end
