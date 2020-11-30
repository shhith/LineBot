desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document' # xmlファイルの読み込み

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  url  = "https://www.drk7.jp/weather/xml/23.xml" # 使用したxmlデータ（毎日朝6時更新)
  xml  = open( url ).read.toutf8
  doc = REXML::Document.new(xml)
  xpath = 'weatherforecast/pref/area[2]/info/rainfallchance/' # パスの共通部分を変数化
  # 6時〜24時の降水確率
  per06to12 = doc.elements[xpath + 'period[2]'].text
  per12to18 = doc.elements[xpath + 'period[3]'].text
  per18to24 = doc.elements[xpath + 'period[4]'].text
  # メッセージを発信する降水確率の下限値の設定
  min_per = 20
  if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
    word1 = [
      "おはよう！！",
      "今日も新しいことに一つ挑戦しよう。",
      "いつもより起きるのちょっと遅いんじゃない？"].sample
    word2 = [
      "お気をつけて！",
      "「これからの人生が、これまでの人生を決める」",
      "「人生はできることに集中することであり、できないことを悔やむことではない」byスティーブン・ホーキング",
      "「奇跡を待つより捨て身の努力よ」by江頭2:50",
      "「自分の人生が今ここにあるってだけで最高の気分だ。なんでもできる」by武井壮"].sample
    # 降水確率によってメッセージを変更する閾値の設定
    mid_per = 50
    if per06to12.to_i >= mid_per || per12to18.to_i >= mid_per || per18to24.to_i >= mid_per
      word3 = "今日は雨が降りそうだから傘を忘れないでね！"
    else
      word3 = "今日は雨が降るかもしれないから折りたたみ傘があると安心だよ！"
    end
    # 発信するメッセージの設定
    push =
      "#{word1}\n#{word3}\n降水確率はこんな感じだよ。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\n#{word2}"
    # メッセージの発信先idを配列で渡す必要があるため、userテーブルよりpluck関数を使ってidを配列で取得
    user_ids = User.all.pluck(:line_id)
    message = {
      type: 'text',
      text: push
    }
    response = client.multicast(user_ids, message)
  end
  "OK"
end