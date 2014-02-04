require 'whenever'

every 1.hours do
  command "maid clean --silent"
end

every 24.hours do
  command "maid clean --silent --rules=~/.maid/daily.rb"
end
