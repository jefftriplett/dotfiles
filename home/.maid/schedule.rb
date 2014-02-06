require 'whenever'

every 30.minutes do
  command "maid clean --silent"
end

every 24.hours do
  command "maid clean --silent --rules=~/.maid/daily.rb"
end
