
Maid.rules do

  rule 'Update homebrew' do
    `brew update`
  end

  hostname = %x/hostname -s/.chomp
  case hostname
    when 'Jeffs-Mac-mini', 'Jeff-Tripletts-iMac', 'TV'
      rule 'Update Jeffs-Mac-mini' do
        `brew upgrade`
      end

    #when 'jeffrey-tripletts-macbook-pro'

  end

  rule 'Cleanup homebrew' do
    `brew cleanup`
  end

end
