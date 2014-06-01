
Maid.rules do
  # **NOTE:** It's recommended you just use this as a template; if you run these rules on your machine without knowing
  # what they do, you might run into unwanted results!

  # inspired by: https://github.com/JohnColvin/.maid/blob/master/rules.rb
  rule 'Update yourself' do
    `homesick pull`
    `homesick symlink`
  end

  rule 'Torrents' do
    dir('~/Downloads/*.torrent').each do |path|
      move(path, '~/Dropbox/Torrents/')
    end
  end

  # inpired by OS name example - https://github.com/mitchty/src/blob/master/dotfiles/maid/rules.rb
  # custom rules based on known machine names
  case %x/hostname -s/.chomp

    when 'jeffrey-tripletts-macbook-pro'

    when 'Jeffs-Mac-mini'

    when 'Jeff-Tripletts-iMac'

    when 'TV'

  end

  rule 'Collect downloaded videos to watch later' do
    move where_content_type(dir('~/Downloads/*'), 'video'), '~/Movies/'
    dir('~/Downloads/*.{mkv,mp4,avi}').each do |path|
      move(path, '~/Movies/')
    end
  end

  rule 'Cleanup Downloads' do
    dir('~/Downloads/*').each do |path|
      if 2.week.since?(accessed_at(path))
        trash(path)
      end
    end
  end

  rule 'Update crontab' do
    `whenever --update-crontab -f ~/.maid/schedule.rb`
  end

  # NOTE: Currently, only Mac OS X supports `duration_s`.
  #rule 'MP3s likely to be music' do
  #  dir('~/Downloads/*.mp3').each do |path|
  #    if duration_s(path) > 30.0
  #      move(path, '~/Music/iTunes/iTunes Media/Automatically Add to iTunes/')
  #    end
  #  end
  #end

end
