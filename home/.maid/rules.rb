
Maid.rules do

  RUN_TIME = Time.now
  DAY_SECONDS = 60 * 60 * 24
  WEEK = DAY_SECONDS * 7
  ONE_WEEK_AGO = (RUN_TIME - WEEK)
  TWO_WEEKS_AGO = (RUN_TIME - WEEK * 2)
  THREE_MONTHS_AGO = (RUN_TIME - (DAY_SECONDS * 93))

  rule 'Update yourself' do
    `homesick pull`
    `homesick symlink`
  end

  # custom rules based on known machine names
  case %x/hostname -s/.chomp

    when 'jeffrey-tripletts-macbook-pro'

    when 'Jeffs-Mac-mini'

    when 'Jeff-Tripletts-iMac'

    when 'TV'

  end

  case %x/uname -s/.chomp
    when 'Darwin'
      rule '/Library/Caches/Homebrew/' do
        dir('/Library/Caches/Homebrew/*.tar.*').each do |path|
          trash path if File.mtime(path) < THREE_MONTHS_AGO
        end
        dir('/Library/Caches/Homebrew/*.tgz').each do |path|
          trash path if File.mtime(path) < THREE_MONTHS_AGO
        end
        dir('/Library/Caches/Homebrew/*.tbz').each do |path|
          trash path if File.mtime(path) < THREE_MONTHS_AGO
        end
      end

      rule '~/Library/Caches' do
        dir('~/Library/Caches/Google/Chrome/Default/Cache/*').each do |path|
          trash path if File.mtime(path) < THREE_MONTHS_AGO
        end
      end

      rule 'Collect downloaded videos to watch later' do
        move where_content_type(dir('~/Downloads/*'), 'video'), '~/Movies/'
        dir('~/Downloads/*.{mkv,mp4,avi}').each do |path|
          move(path, '~/Movies/')
        end
      end

      rule 'Cleanup Downloads + Desktop' do
        ["~/Downloads", "~/Desktop"].each do |junk_drawer|
          dir("#{junk_drawer}/*").each do |path|
            if 2.week.since?(accessed_at(path))
              trash(path)
            end
          end
        end
      end
  end

  rule 'Update crontab' do
    `whenever --update-crontab -f ~/.maid/schedule.rb`
  end
end
