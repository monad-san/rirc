
#
# DiceBot -- roll a dice
#

class DiceBot < Rirc::Bot
  def ch_privmsg(m)
    s = ''
    t = 0
    
    if m =~ /^\#(\d+)d(\d+)/ then
      Integer($1).times do
        r = 1 + rand(Integer($2))
        s << " #{r}"
        t += r
      end
      notice "#{$1}d#{$2} => #{t}(#{s} )"
    end
  end
end

