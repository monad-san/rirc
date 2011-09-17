
class EchoBot < Btmonad::Bot
  def ch_privmsg(m)
    notice m
  end
end

