
Maid.rules do

  rule 'Update homebrew' do
    `brew update`
  end

  case %x/hostname -s/.chomp
    when 'jeffrey-tripletts-macbook-pro'
      print "==jeffrey-tripletts-macbook-pro::daily()\n"

    when 'Jeffs-Mac-mini'
      print "==Jeffs-Mac-mini::daily()\n"

      rule 'Update Jeffs-Mac-mini' do
        `brew upgrade`
      end

  end

  rule 'Cleanup homebrew' do
    `brew cleanup`
  end

end
