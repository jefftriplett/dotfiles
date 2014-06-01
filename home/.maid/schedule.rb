require 'whenever'

every 30.minutes do
  command "maid clean --noop --silent"
end

every 24.hours do
  command "maid clean --noop --silent --rules=~/.maid/daily.rb"
end
