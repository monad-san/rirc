
#
# OpStore -- distribute oper
#

class OpStore < Rirc::Bot
  def on_join(m)
    nick = m.prefix.split('!')[0]
    if nick != Rirc::Config["nick"]
      @post.call "MODE", m[0], "+o", nick
    end
  end
end

